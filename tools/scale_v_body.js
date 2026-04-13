#!/usr/bin/env node
/**
 * Scale V Body Shape — Proper Archive Rebuild
 *
 * Decompresses all segments, modifies animRig bone translations for height,
 * recompresses, and rebuilds the archive matching WolvenKit's ArchiveWriter
 * format exactly.
 */
const fs = require('fs');
const path = require('path');
const koffi = require('koffi');

const krakenLib = koffi.load(path.join(__dirname, '..', 'WolvenKit.Core', 'lib', 'libkraken.so'));
const Kraken_Decompress = krakenLib.func('int Kraken_Decompress(const uint8_t* src, long src_len, uint8_t* dst, long dst_len)');
const Kraken_Compress = krakenLib.func('int Kraken_Compress(const uint8_t* src, long src_len, uint8_t* dst, int level)');

const RDAR_MAGIC = 0x52414452;
const KARK_MAGIC = 0x4B52414B;
const HEIGHT_SCALE = 1.1;

// ─── Archive I/O ─────────────────────────────────────────────────
function parseArchive(buf) {
    if (buf.readUInt32LE(0) !== RDAR_MAGIC) throw new Error('Not RDAR');
    const header = {
        version: buf.readUInt32LE(4),
        indexPosition: Number(buf.readBigUInt64LE(8)),
        indexSize: buf.readUInt32LE(16),
        debugPosition: Number(buf.readBigUInt64LE(20)),
        debugSize: buf.readUInt32LE(28),
        filesize: Number(buf.readBigUInt64LE(32)),
    };

    // The custom data length is at offset 0xA4 (inside the 0xA8-byte extended header)
    // But there's also an SRXL block that starts at 0xAC in this archive
    // We need to preserve everything from 0 to the first segment offset

    let pos = header.indexPosition;
    pos += 4 + 4 + 8; // fileTableOffset + fileTableSize + crc
    const fec = buf.readUInt32LE(pos); pos += 4;
    const fsc = buf.readUInt32LE(pos); pos += 4;
    const rdc = buf.readUInt32LE(pos); pos += 4;

    const entries = [];
    for (let i = 0; i < fec; i++) {
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
    for (let i = 0; i < fsc; i++) {
        const offset = Number(buf.readBigUInt64LE(pos)); pos += 8;
        const zsize = buf.readUInt32LE(pos); pos += 4;
        const size = buf.readUInt32LE(pos); pos += 4;
        segments.push({ offset, zsize, size });
    }

    const deps = [];
    for (let i = 0; i < rdc; i++) {
        deps.push(buf.readBigUInt64LE(pos)); pos += 8;
    }

    return { buf, header, entries, segments, deps };
}

function decompressSegment(buf, seg) {
    if (seg.zsize === seg.size) return Buffer.from(buf.subarray(seg.offset, seg.offset + seg.size));
    const magic = buf.readUInt32LE(seg.offset);
    if (magic === KARK_MAGIC) {
        const expectedSize = buf.readUInt32LE(seg.offset + 4);
        const compData = Buffer.from(buf.subarray(seg.offset + 8, seg.offset + seg.zsize));
        const outBuf = Buffer.alloc(expectedSize);
        Kraken_Decompress(compData, compData.length, outBuf, expectedSize);
        return outBuf;
    }
    // Not KARK - try raw
    const compData = Buffer.from(buf.subarray(seg.offset, seg.offset + seg.zsize));
    const outBuf = Buffer.alloc(seg.size);
    Kraken_Decompress(compData, compData.length, outBuf, seg.size);
    return outBuf;
}

function compressSegment(rawBuf) {
    // Matching WolvenKit: compress with Kraken, add KARK header
    // Small buffers (<= 256 bytes) are stored uncompressed
    if (rawBuf.length <= 256) return rawBuf;

    const maxOut = rawBuf.length + Math.ceil(rawBuf.length * 0.2) + 2048;
    const outBuf = Buffer.alloc(maxOut);
    const r = Kraken_Compress(rawBuf, rawBuf.length, outBuf, 4); // Level 4 = Normal

    // If compression doesn't help, store raw
    if (r <= 0 || rawBuf.length <= (r + 8)) return rawBuf;

    const result = Buffer.alloc(8 + r);
    result.writeUInt32LE(KARK_MAGIC, 0);
    result.writeUInt32LE(rawBuf.length, 4);
    outBuf.copy(result, 8, 0, r);
    return result;
}

// ─── CR2W helper ─────────────────────────────────────────────────
function getCR2WClassName(data) {
    if (data.length < 0xA2 || data[0] !== 0x43 || data[1] !== 0x52 || data[2] !== 0x32 || data[3] !== 0x57) return null;
    let end = 0xA1;
    while (end < data.length && end < 0x200 && data[end] !== 0) end++;
    return data.toString('utf8', 0xA1, end);
}

// ─── Height scaling ──────────────────────────────────────────────
function scaleRigForHeight(data) {
    const hipsRotOffsets = [];
    for (let i = 16; i < data.length - 32; i += 4) {
        const qi = data.readFloatLE(i);
        const qk = data.readFloatLE(i + 8);
        if (qi > 0.68 && qi < 0.73 && qk > 0.68 && qk < 0.73 && Math.abs(qi - qk) < 0.005) {
            const qj = data.readFloatLE(i + 4);
            const qr = data.readFloatLE(i + 12);
            if (qj < -0.01 && qr < -0.01 && Math.abs(qj - qr) < 0.005) {
                const rl = Math.sqrt(qi*qi + qj*qj + qk*qk + qr*qr);
                if (Math.abs(rl - 1.0) < 0.02) {
                    const hz = data.readFloatLE(i - 8);
                    if (hz > 0.7 && hz < 1.5) hipsRotOffsets.push(i);
                }
            }
        }
    }

    let totalMods = 0;
    for (const hipsRotOff of hipsRotOffsets) {
        const hipsTransOff = hipsRotOff - 16;
        const hipsZ = data.readFloatLE(hipsTransOff + 8);
        if (hipsZ < 0.7 || hipsZ > 1.5) continue;

        data.writeFloatLE(hipsZ * HEIGHT_SCALE, hipsTransOff + 8);
        console.log(`    Hips Z: ${hipsZ.toFixed(4)} → ${(hipsZ * HEIGHT_SCALE).toFixed(4)}`);
        totalMods++;

        let off = hipsTransOff + 48;
        let count = 0;
        while (off + 48 < data.length && count < 250) {
            const ri = data.readFloatLE(off + 16), rj = data.readFloatLE(off + 20);
            const rk = data.readFloatLE(off + 24), rr = data.readFloatLE(off + 28);
            const rl = Math.sqrt(ri*ri + rj*rj + rk*rk + rr*rr);
            if (!isFinite(rl) || Math.abs(rl - 1.0) > 0.02) break;

            const tx = data.readFloatLE(off);
            if (Math.abs(tx) > 0.001) { data.writeFloatLE(tx * HEIGHT_SCALE, off); totalMods++; }
            const ty = data.readFloatLE(off + 4);
            if (Math.abs(ty) > 0.001) { data.writeFloatLE(ty * HEIGHT_SCALE, off + 4); }

            off += 48;
            count++;
        }
        console.log(`    Scaled ${count + 1} bones`);
    }
    return totalMods;
}

// ─── Page alignment ──────────────────────────────────────────────
function padToPage(size) { const r = size % 4096; return r === 0 ? 0 : 4096 - r; }

// ─── CRC64 (ECMA-182 used by WolvenKit) ─────────────────────────
// The game reads the CRC but mod archives typically have it zeroed.
// WolvenKit's Crc64.Compute uses the ECMA polynomial.
// We'll set it to the value from the original archive or 0.

// ─── Main ────────────────────────────────────────────────────────
function main() {
    const archivePath = path.join(__dirname, '..', 'Unique V Body Shape', 'pc', 'mod', 'zz_johnson_Framework_Unique_V_Body_Shape.archive');

    console.log('============================================');
    console.log('  Unique V Body Shape — Height Scaler');
    console.log(`  Height: ${HEIGHT_SCALE}x`);
    console.log('============================================\n');

    const archive = parseArchive(fs.readFileSync(archivePath));
    console.log(`Archive: ${archive.entries.length} files, ${archive.segments.length} segments\n`);

    // Step 1: Decompress all segments
    const decompSegs = archive.segments.map((seg, i) => {
        try { return decompressSegment(archive.buf, seg); }
        catch (e) { console.error(`  Seg ${i}: ${e.message}`); return null; }
    });

    // Step 2: Find and modify animRig files
    let totalMods = 0;
    for (let fi = 0; fi < archive.entries.length; fi++) {
        const entry = archive.entries[fi];
        const data = decompSegs[entry.segStart];
        if (!data) continue;
        const cls = getCR2WClassName(data);
        if (cls !== 'animRig') continue;

        console.log(`[${fi}] animRig (${fi < 8 ? 'male' : 'female'})`);
        totalMods += scaleRigForHeight(data);
    }

    if (totalMods === 0) { console.log('ERROR: No modifications!'); process.exit(1); }
    console.log(`\nTotal: ${totalMods} modifications\n`);

    // Step 3: Recompress ALL segments
    const compSegs = decompSegs.map((raw, i) => {
        if (!raw) return Buffer.from(archive.buf.subarray(archive.segments[i].offset, archive.segments[i].offset + archive.segments[i].zsize));
        const origWasCompressed = archive.segments[i].zsize !== archive.segments[i].size;
        if (!origWasCompressed) return raw;
        return compressSegment(raw);
    });

    // Step 4: Rebuild archive (matching WolvenKit ArchiveWriter exactly)
    console.log('Rebuilding archive...');

    // 4a: Preserve header area (0x00 to first segment)
    const firstSegOff = archive.segments[0].offset;
    const headerArea = Buffer.from(archive.buf.subarray(0, firstSegOff));

    // 4b: Write segments sequentially
    const newSegments = [];
    let writePos = firstSegOff;
    const segBuffers = [];

    for (let i = 0; i < compSegs.length; i++) {
        const segData = compSegs[i];
        const origSeg = archive.segments[i];
        const rawSize = decompSegs[i] ? decompSegs[i].length : origSeg.size;
        const isCompressed = segData.length !== rawSize;

        newSegments.push({
            offset: writePos,
            zsize: segData.length,
            size: rawSize
        });

        segBuffers.push(segData);
        writePos += segData.length;
    }

    // 4c: Page-align before index
    const dataPadding = padToPage(writePos);
    writePos += dataPadding;

    const indexPosition = writePos;

    // 4d: Build index (exactly matching ArchiveWriter.WriteIndex)
    // Index layout: fileTableOffset(4) + fileTableSize(4) + CRC64(8) + counts(12) + entries + segments + deps

    const entryBytes = archive.entries.length * 56;
    const segBytes = newSegments.length * 16;
    const depBytes = archive.deps.length * 8;
    const tableContentBytes = 4 + 4 + 4 + entryBytes + segBytes + depBytes; // counts + data
    const indexSize = 4 + 4 + 8 + tableContentBytes; // fileTableOffset + fileTableSize + CRC + content

    const indexBuf = Buffer.alloc(indexSize);
    let ip = 0;

    // fileTableOffset (WolvenKit always writes 8)
    indexBuf.writeUInt32LE(8, ip); ip += 4;
    // fileTableSize (ms.Length + 8 per WolvenKit)
    indexBuf.writeUInt32LE(tableContentBytes + 8, ip); ip += 4;
    // CRC64 - read from original archive
    const origCrc = archive.buf.readBigUInt64LE(archive.header.indexPosition + 8);
    indexBuf.writeBigUInt64LE(origCrc, ip); ip += 8;
    // Counts
    indexBuf.writeUInt32LE(archive.entries.length, ip); ip += 4;
    indexBuf.writeUInt32LE(newSegments.length, ip); ip += 4;
    indexBuf.writeUInt32LE(archive.deps.length, ip); ip += 4;

    // File entries (unchanged)
    for (const e of archive.entries) {
        indexBuf.writeBigUInt64LE(e.nameHash, ip); ip += 8;
        indexBuf.writeBigInt64LE(e.timestamp, ip); ip += 8;
        indexBuf.writeUInt32LE(e.numInline, ip); ip += 4;
        indexBuf.writeUInt32LE(e.segStart, ip); ip += 4;
        indexBuf.writeUInt32LE(e.segEnd, ip); ip += 4;
        indexBuf.writeUInt32LE(e.depStart, ip); ip += 4;
        indexBuf.writeUInt32LE(e.depEnd, ip); ip += 4;
        e.sha1.copy(indexBuf, ip); ip += 20;
    }

    // Segment entries (updated offsets/sizes)
    for (const s of newSegments) {
        indexBuf.writeBigUInt64LE(BigInt(s.offset), ip); ip += 8;
        indexBuf.writeUInt32LE(s.zsize, ip); ip += 4;
        indexBuf.writeUInt32LE(s.size, ip); ip += 4;
    }

    // Dependencies
    for (const d of archive.deps) {
        indexBuf.writeBigUInt64LE(d, ip); ip += 8;
    }

    writePos += indexSize;

    // 4e: Final page padding
    const finalPadding = padToPage(writePos);
    writePos += finalPadding;

    // 4f: Update header
    headerArea.writeBigUInt64LE(BigInt(indexPosition), 8);  // indexPosition
    headerArea.writeUInt32LE(indexSize, 16);                 // indexSize
    headerArea.writeBigUInt64LE(BigInt(writePos), 32);       // filesize

    // 4g: Assemble
    const output = Buffer.concat([
        headerArea,
        ...segBuffers,
        Buffer.alloc(dataPadding),
        indexBuf,
        Buffer.alloc(finalPadding)
    ]);

    console.log(`Original: ${archive.buf.length} bytes`);
    console.log(`New:      ${output.length} bytes`);
    console.log(`Index at: ${indexPosition}`);

    // Sanity checks
    if (output.readUInt32LE(0) !== RDAR_MAGIC) { console.error('BAD MAGIC'); process.exit(1); }
    if (Number(output.readBigUInt64LE(32)) !== output.length) { console.error('SIZE MISMATCH'); process.exit(1); }

    fs.writeFileSync(archivePath, output);
    console.log(`\nWritten: ${archivePath}`);
    console.log('\n============================================');
    console.log(`  V is now ${HEIGHT_SCALE}x taller!`);
    console.log('============================================');
}

main();
