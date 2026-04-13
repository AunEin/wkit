#!/usr/bin/env node
/**
 * Scale V Body Shape Archive Tool
 *
 * Reads a Cyberpunk 2077 .archive (RDAR format), decompresses all files,
 * finds animRig files containing QsTransform bone data, scales translation
 * values by SCALE_FACTOR to make V's body bigger, then recompresses and
 * writes a new archive.
 */
const fs = require('fs');
const path = require('path');
const koffi = require('koffi');

// ─── Load Kraken native library ──────────────────────────────────
const krakenLib = koffi.load(path.join(__dirname, '..', 'WolvenKit.Core', 'lib', 'libkraken.so'));
const Kraken_Decompress = krakenLib.func('int Kraken_Decompress(const uint8_t* src, long src_len, uint8_t* dst, long dst_len)');
const Kraken_Compress = krakenLib.func('int Kraken_Compress(const uint8_t* src, long src_len, uint8_t* dst, int level)');

// ─── Constants ───────────────────────────────────────────────────
const RDAR_MAGIC = 0x52414452;
const KARK_MAGIC = 0x4B52414B;
const SCALE_FACTOR = 1.1;
const QS_TRANSFORM_SIZE = 48; // 3 x Vector4/Quaternion = 3 x 16 bytes

// ─── Compression Helpers ─────────────────────────────────────────
function decompressSegment(buf, offset, zsize, size) {
    if (zsize === size) return Buffer.from(buf.subarray(offset, offset + size));

    const magic = buf.readUInt32LE(offset);
    if (magic === KARK_MAGIC) {
        const expectedSize = buf.readUInt32LE(offset + 4);
        const compData = Buffer.from(buf.subarray(offset + 8, offset + zsize));
        const outBuf = Buffer.alloc(expectedSize);
        const r = Kraken_Decompress(compData, compData.length, outBuf, expectedSize);
        if (r < 0) throw new Error(`KARK decompress failed: ${r}`);
        return outBuf;
    }

    const compData = Buffer.from(buf.subarray(offset, offset + zsize));
    const outBuf = Buffer.alloc(size);
    const r = Kraken_Decompress(compData, compData.length, outBuf, size);
    if (r < 0) throw new Error(`Raw decompress failed: ${r}`);
    return outBuf;
}

function compressToKARK(rawBuf) {
    if (rawBuf.length <= 256) return rawBuf;

    const maxOut = rawBuf.length + Math.ceil(rawBuf.length * 0.2) + 2048;
    const outBuf = Buffer.alloc(maxOut);
    const r = Kraken_Compress(rawBuf, rawBuf.length, outBuf, 4);
    if (r <= 0 || r + 8 >= rawBuf.length) return rawBuf;

    const result = Buffer.alloc(8 + r);
    result.writeUInt32LE(KARK_MAGIC, 0);
    result.writeUInt32LE(rawBuf.length, 4);
    outBuf.copy(result, 8, 0, r);
    return result;
}

// ─── Archive Parser ──────────────────────────────────────────────
function parseArchive(filePath) {
    const buf = fs.readFileSync(filePath);
    if (buf.readUInt32LE(0) !== RDAR_MAGIC) throw new Error('Not RDAR');

    const header = {
        version: buf.readUInt32LE(4),
        indexPosition: Number(buf.readBigUInt64LE(8)),
        indexSize: buf.readUInt32LE(16),
        debugPosition: Number(buf.readBigUInt64LE(20)),
        debugSize: buf.readUInt32LE(28),
        filesize: Number(buf.readBigUInt64LE(32)),
    };

    let pos = header.indexPosition;
    const fileTableOffset = buf.readUInt32LE(pos); pos += 4;
    const fileTableSize = buf.readUInt32LE(pos); pos += 4;
    const crc = buf.readBigUInt64LE(pos); pos += 8;
    const fileEntryCount = buf.readUInt32LE(pos); pos += 4;
    const fileSegmentCount = buf.readUInt32LE(pos); pos += 4;
    const resourceDepCount = buf.readUInt32LE(pos); pos += 4;

    const entries = [];
    for (let i = 0; i < fileEntryCount; i++) {
        const nameHash = buf.readBigUInt64LE(pos); pos += 8;
        const timestamp = buf.readBigInt64LE(pos); pos += 8;
        const numInline = buf.readUInt32LE(pos); pos += 4;
        const segStart = buf.readUInt32LE(pos); pos += 4;
        const segEnd = buf.readUInt32LE(pos); pos += 4;
        const depStart = buf.readUInt32LE(pos); pos += 4;
        const depEnd = buf.readUInt32LE(pos); pos += 4;
        const sha1 = Buffer.from(buf.subarray(pos, pos + 20)); pos += 20;
        entries.push({ nameHash, timestamp, numInline, segStart, segEnd, depStart, depEnd, sha1 });
    }

    const segments = [];
    for (let i = 0; i < fileSegmentCount; i++) {
        const offset = Number(buf.readBigUInt64LE(pos)); pos += 8;
        const zsize = buf.readUInt32LE(pos); pos += 4;
        const size = buf.readUInt32LE(pos); pos += 4;
        segments.push({ offset, zsize, size });
    }

    const deps = [];
    for (let i = 0; i < resourceDepCount; i++) {
        deps.push(buf.readBigUInt64LE(pos)); pos += 8;
    }

    return { buf, header, entries, segments, deps };
}

// ─── CR2W Class Name ─────────────────────────────────────────────
function getCR2WClassName(data) {
    if (data.length < 0xA2) return null;
    if (data[0] !== 0x43 || data[1] !== 0x52 || data[2] !== 0x32 || data[3] !== 0x57) return null;
    let end = 0xA1;
    while (end < data.length && end < 0x200 && data[end] !== 0) end++;
    return data.toString('utf8', 0xA1, end);
}

// ─── Find QsTransform arrays in animRig ──────────────────────────
// QsTransform = Translation(Vector4:16B) + Rotation(Quaternion:16B) + Scale(Vector4:16B) = 48 bytes
// Scale default = (1,1,1,1), Rotation default = (0,0,0,1)
// We find contiguous runs of valid QsTransforms

function findQsTransformArrays(data) {
    const arrays = [];

    // Search for the start of QsTransform arrays by looking for
    // sequences of valid quaternions followed by (1,1,1,1) scale
    const oneFloat = Buffer.alloc(4);
    oneFloat.writeFloatLE(1.0, 0);
    const scaleIdentity = Buffer.concat([oneFloat, oneFloat, oneFloat, oneFloat]);

    // Find all scale identity positions
    const scalePositions = [];
    for (let i = 0; i < data.length - 16; i += 4) {
        if (data.subarray(i, i + 16).equals(scaleIdentity)) {
            // Verify this is preceded by a valid quaternion (16 bytes before)
            if (i >= 16) {
                const qi = data.readFloatLE(i - 16);
                const qj = data.readFloatLE(i - 12);
                const qk = data.readFloatLE(i - 8);
                const qr = data.readFloatLE(i - 4);
                const rotLen = Math.sqrt(qi * qi + qj * qj + qk * qk + qr * qr);
                if (isFinite(rotLen) && Math.abs(rotLen - 1.0) < 0.01) {
                    scalePositions.push(i);
                }
            }
        }
    }

    if (scalePositions.length < 10) return arrays;

    // Group consecutive transforms (48-byte spacing)
    let arrayStart = -1;
    let prevPos = -1;
    let currentArray = [];

    for (const pos of scalePositions) {
        if (prevPos === -1 || pos - prevPos === QS_TRANSFORM_SIZE) {
            if (arrayStart === -1) arrayStart = pos - 32; // translation starts 32 bytes before scale
            currentArray.push(pos);
        } else if (pos - prevPos === 4) {
            // Adjacent (1,1,1,1) blocks - the first one is the Scale W, next starts Translation
            // This happens when Translation starts with 1.0
            // Skip this ambiguity
        } else {
            // Gap - save current array and start new one
            if (currentArray.length >= 5) {
                arrays.push({ start: arrayStart, scaleOffsets: [...currentArray], count: currentArray.length });
            }
            arrayStart = pos - 32;
            currentArray = [pos];
        }
        prevPos = pos;
    }

    if (currentArray.length >= 5) {
        arrays.push({ start: arrayStart, scaleOffsets: [...currentArray], count: currentArray.length });
    }

    return arrays;
}

// ─── Scale QsTransform translations ──────────────────────────────
function scaleRigTransforms(data, scaleFactor) {
    const arrays = findQsTransformArrays(data);
    let totalMods = 0;

    for (const arr of arrays) {
        console.log(`  Found QsTransform array: ${arr.count} transforms starting at offset ${arr.start}`);

        // For each transform, scale the Translation vector
        for (const scaleOff of arr.scaleOffsets) {
            const transOff = scaleOff - 32; // Translation is 32 bytes before Scale
            if (transOff < 0) continue;

            const tx = data.readFloatLE(transOff);
            const ty = data.readFloatLE(transOff + 4);
            const tz = data.readFloatLE(transOff + 8);
            // tw at transOff+12 is typically 0 (positional, not directional)

            // Scale translation to make skeleton bigger
            data.writeFloatLE(tx * scaleFactor, transOff);
            data.writeFloatLE(ty * scaleFactor, transOff + 4);
            data.writeFloatLE(tz * scaleFactor, transOff + 8);

            // Scale the Scale vector too (make each bone slightly larger)
            const sx = data.readFloatLE(scaleOff);
            const sy = data.readFloatLE(scaleOff + 4);
            const sz = data.readFloatLE(scaleOff + 8);
            const sw = data.readFloatLE(scaleOff + 12);

            data.writeFloatLE(sx * scaleFactor, scaleOff);
            data.writeFloatLE(sy * scaleFactor, scaleOff + 4);
            data.writeFloatLE(sz * scaleFactor, scaleOff + 8);
            // Keep W as-is

            totalMods++;
        }
    }

    return totalMods;
}

// ─── CRC64 (simplified - game doesn't strictly verify for mods) ──
function crc64(buf) {
    // Return 0 - CP2077 doesn't validate archive CRC for mod archives
    return 0n;
}

// ─── Pad to 4096 page boundary ──────────────────────────────────
function padToPage(currentSize) {
    const remainder = currentSize % 4096;
    return remainder === 0 ? 0 : 4096 - remainder;
}

// ─── Build new archive ───────────────────────────────────────────
function buildArchive(archive, decompressedSegs, modifiedSegIndices) {
    const chunks = [];
    let offset = 0;

    // 1. Write header placeholder (0xA8 bytes)
    const headerBuf = Buffer.alloc(0xA8);
    chunks.push(headerBuf);
    offset += 0xA8;

    // 2. Write custom data (between 0xA8 and first segment offset)
    const firstSegOffset = archive.segments[0].offset;
    if (firstSegOffset > 0xA8) {
        const customData = Buffer.from(archive.buf.subarray(0xA8, firstSegOffset));
        chunks.push(customData);
        offset += customData.length;
    }

    // 3. Write file segments (compressed)
    const newSegments = [];

    for (let si = 0; si < archive.segments.length; si++) {
        const origSeg = archive.segments[si];
        const decompData = decompressedSegs[si];

        let segData;
        if (decompData && (origSeg.zsize !== origSeg.size)) {
            // Was compressed - recompress
            segData = compressToKARK(decompData);
        } else if (decompData) {
            // Was uncompressed
            segData = decompData;
        } else {
            // Couldn't decompress - keep original
            segData = Buffer.from(archive.buf.subarray(origSeg.offset, origSeg.offset + origSeg.zsize));
        }

        newSegments.push({
            offset: offset,
            zsize: segData.length,
            size: decompData ? decompData.length : origSeg.size
        });

        chunks.push(segData);
        offset += segData.length;
    }

    // 4. Pad to page boundary
    const dataPad = padToPage(offset);
    if (dataPad > 0) {
        chunks.push(Buffer.alloc(dataPad));
        offset += dataPad;
    }

    const indexStart = offset;

    // 5. Build index
    // Index header: fileTableOffset(4) + fileTableSize(4) + crc(8) + counts(12) = 32 bytes
    // Then: entries + segments + deps

    const entrySize = 56; // 8+8+4+4+4+4+4+20
    const segSize = 16;   // 8+4+4
    const depSize = 8;

    const tableContentSize = (archive.entries.length * entrySize) + (newSegments.length * segSize) + (archive.deps.length * depSize);
    const indexHeaderSize = 4 + 4 + 8 + 4 + 4 + 4; // 28 bytes
    const indexTotalSize = indexHeaderSize + tableContentSize;

    const indexBuf = Buffer.alloc(indexTotalSize);
    let ipos = 0;

    // fileTableOffset (always 8)
    indexBuf.writeUInt32LE(8, ipos); ipos += 4;
    // fileTableSize
    indexBuf.writeUInt32LE(tableContentSize + 8, ipos); ipos += 4;
    // CRC64 (0 for mod archives)
    indexBuf.writeBigUInt64LE(0n, ipos); ipos += 8;
    // counts
    indexBuf.writeUInt32LE(archive.entries.length, ipos); ipos += 4;
    indexBuf.writeUInt32LE(newSegments.length, ipos); ipos += 4;
    indexBuf.writeUInt32LE(archive.deps.length, ipos); ipos += 4;

    // File entries
    for (const entry of archive.entries) {
        indexBuf.writeBigUInt64LE(entry.nameHash, ipos); ipos += 8;
        indexBuf.writeBigInt64LE(entry.timestamp, ipos); ipos += 8;
        indexBuf.writeUInt32LE(entry.numInline, ipos); ipos += 4;
        indexBuf.writeUInt32LE(entry.segStart, ipos); ipos += 4;
        indexBuf.writeUInt32LE(entry.segEnd, ipos); ipos += 4;
        indexBuf.writeUInt32LE(entry.depStart, ipos); ipos += 4;
        indexBuf.writeUInt32LE(entry.depEnd, ipos); ipos += 4;
        entry.sha1.copy(indexBuf, ipos); ipos += 20;
    }

    // File segments
    for (const seg of newSegments) {
        indexBuf.writeBigUInt64LE(BigInt(seg.offset), ipos); ipos += 8;
        indexBuf.writeUInt32LE(seg.zsize, ipos); ipos += 4;
        indexBuf.writeUInt32LE(seg.size, ipos); ipos += 4;
    }

    // Dependencies
    for (const dep of archive.deps) {
        indexBuf.writeBigUInt64LE(dep, ipos); ipos += 8;
    }

    chunks.push(indexBuf);
    offset += indexTotalSize;

    // 6. Final page padding
    const finalPad = padToPage(offset);
    if (finalPad > 0) {
        chunks.push(Buffer.alloc(finalPad));
        offset += finalPad;
    }

    // 7. Write header
    headerBuf.writeUInt32LE(RDAR_MAGIC, 0);
    headerBuf.writeUInt32LE(archive.header.version, 4);
    headerBuf.writeBigUInt64LE(BigInt(indexStart), 8);
    headerBuf.writeUInt32LE(indexTotalSize, 16);
    headerBuf.writeBigUInt64LE(BigInt(archive.header.debugPosition), 20);
    headerBuf.writeUInt32LE(archive.header.debugSize, 28);
    headerBuf.writeBigUInt64LE(BigInt(offset), 32);
    // Copy remaining header bytes (padding, custom data length etc)
    archive.buf.copy(headerBuf, 40, 40, 0xA8);

    return Buffer.concat(chunks);
}

// ─── Main ────────────────────────────────────────────────────────
function main() {
    const archivePath = path.join(__dirname, '..', 'Unique V Body Shape', 'pc', 'mod', 'zz_johnson_Framework_Unique_V_Body_Shape.archive');

    console.log('============================================');
    console.log('  Unique V Body Shape - Scale Tool');
    console.log(`  Scale Factor: ${SCALE_FACTOR}x`);
    console.log('============================================\n');

    // Backup original
    const backupPath = archivePath + '.backup';
    if (!fs.existsSync(backupPath)) {
        fs.copyFileSync(archivePath, backupPath);
        console.log(`Backup created: ${backupPath}\n`);
    }

    const archive = parseArchive(archivePath);
    console.log(`Archive: ${archive.entries.length} files, ${archive.segments.length} segments\n`);

    // Decompress all segments
    const decompressedSegs = [];
    for (let i = 0; i < archive.segments.length; i++) {
        const seg = archive.segments[i];
        try {
            decompressedSegs.push(decompressSegment(archive.buf, seg.offset, seg.zsize, seg.size));
        } catch (e) {
            console.error(`  Segment ${i} decompress error: ${e.message}`);
            decompressedSegs.push(null);
        }
    }

    // Process each file
    let totalModifications = 0;
    const modifiedSegments = new Set();

    for (let fi = 0; fi < archive.entries.length; fi++) {
        const entry = archive.entries[fi];
        const firstSegData = decompressedSegs[entry.segStart];
        if (!firstSegData) continue;

        const className = getCR2WClassName(firstSegData);
        const numSegs = entry.segEnd - entry.segStart;

        if (className === 'animRig') {
            console.log(`[${fi}] ${className} (hash: ${entry.nameHash.toString(16).padStart(16, '0')}, ${numSegs} segments)`);

            const mods = scaleRigTransforms(firstSegData, SCALE_FACTOR);
            if (mods > 0) {
                modifiedSegments.add(entry.segStart);
                totalModifications += mods;
                console.log(`  >> Scaled ${mods} bone transforms by ${SCALE_FACTOR}x\n`);
            }
        } else {
            // For entity templates, also check buffer segments for embedded data
            // that might reference scale transforms
        }
    }

    console.log(`\nTotal: ${totalModifications} bone transforms modified across ${modifiedSegments.size} segments\n`);

    if (totalModifications === 0) {
        console.log('ERROR: No modifications made!');
        process.exit(1);
    }

    // Rebuild archive
    console.log('Rebuilding archive...');
    const newArchive = buildArchive(archive, decompressedSegs, modifiedSegments);

    // Verify
    console.log(`Original size: ${archive.buf.length} bytes`);
    console.log(`New size:      ${newArchive.length} bytes`);

    if (newArchive.readUInt32LE(0) !== RDAR_MAGIC) {
        console.error('ERROR: Output magic mismatch!');
        process.exit(1);
    }

    // Quick verification: re-parse and decompress a modified segment
    const verifyArchive = parseArchive.bind(null); // Can't re-parse from buffer directly, so verify header
    const newIndexPos = Number(newArchive.readBigUInt64LE(8));
    const newFileSize = Number(newArchive.readBigUInt64LE(32));
    console.log(`New index position: ${newIndexPos}`);
    console.log(`New file size: ${newFileSize}`);

    if (newFileSize !== newArchive.length) {
        console.error(`ERROR: File size mismatch! Header says ${newFileSize} but actual is ${newArchive.length}`);
        process.exit(1);
    }

    // Write output
    fs.writeFileSync(archivePath, newArchive);
    console.log(`\nWritten: ${archivePath}`);
    console.log('\n============================================');
    console.log('  Done! V body shape scaled to ' + SCALE_FACTOR + 'x');
    console.log('============================================');
}

main();
