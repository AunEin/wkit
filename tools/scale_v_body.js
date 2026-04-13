#!/usr/bin/env node
/**
 * Scale V Body Shape Archive Tool — HEIGHT FOCUSED
 *
 * Makes V taller (1.1x) without making V wider/thicker (no shortstack).
 * Works by finding bone translation floats in animRig CR2W files,
 * scaling bone-length (X) and height (Hips Z) while keeping lateral widths.
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

// ─── Compression ─────────────────────────────────────────────────
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

// ─── Archive I/O ─────────────────────────────────────────────────
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
    pos += 4 + 4 + 8; // skip fileTableOffset, fileTableSize, crc
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

function getCR2WClassName(data) {
    if (data.length < 0xA2 || data[0] !== 0x43 || data[1] !== 0x52 || data[2] !== 0x32 || data[3] !== 0x57) return null;
    let end = 0xA1;
    while (end < data.length && end < 0x200 && data[end] !== 0) end++;
    return data.toString('utf8', 0xA1, end);
}

function padToPage(size) { const r = size % 4096; return r === 0 ? 0 : 4096 - r; }

// ─── Height-focused bone scaling ─────────────────────────────────
// Strategy: find QsTransform data by locating the Hips rotation quaternion
// (a unique ~0.7017 pattern), then work outward to find Translation vectors.
// Scale bone-length translations (X in bone-local space) by HEIGHT_SCALE.
// Scale Hips Z (world height) by HEIGHT_SCALE.
// Leave lateral offsets (shoulder width, hip width) unchanged.

function scaleRigForHeight(data) {
    // Find the aPoseLS and aPoseMS arrays by locating known bone values.
    // We know the Hips rotation quaternion is unique: (0.7017, -0.0873, 0.7017, -0.0873)

    // Step 1: Find Hips rotation quaternion — both male and female variants
    // Male Hips:   qi~0.7017, qj~-0.0873, qk~0.7017, qr~-0.0873
    // Female Hips: qi~0.7041, qj~-0.0654, qk~0.7041, qr~-0.0654
    // Common pattern: qi~0.70, qk~qi, qj<0, qr~qj, |qi|≈|qk|, |qj|≈|qr|
    const hipsRotOffsets = [];
    for (let i = 16; i < data.length - 16; i += 4) {
        const qi = data.readFloatLE(i);
        const qj = data.readFloatLE(i + 4);
        const qk = data.readFloatLE(i + 8);
        const qr = data.readFloatLE(i + 12);
        // Looking for the Hips rotation: qi ≈ 0.70, qk ≈ qi, qj ≈ qr, qj < 0
        if (qi > 0.69 && qi < 0.72 && qk > 0.69 && qk < 0.72 &&
            Math.abs(qi - qk) < 0.001 && qj < -0.01 && qr < -0.01 &&
            Math.abs(qj - qr) < 0.001) {
            const rotLen = Math.sqrt(qi*qi + qj*qj + qk*qk + qr*qr);
            if (Math.abs(rotLen - 1.0) < 0.01) {
                // Verify: Translation Z before this should be a reasonable hip height (0.8 - 1.2)
                const hipsZ = data.readFloatLE(i - 8);
                if (hipsZ > 0.8 && hipsZ < 1.3) {
                    hipsRotOffsets.push(i);
                }
            }
        }
    }

    console.log(`  Hips rotation candidates found: ${hipsRotOffsets.length}`);
    if (hipsRotOffsets.length === 0) {
        // Fallback: wider search for any quaternion with qi≈qk≈0.70 pattern
        console.log('  Trying wider search...');
        for (let i = 16; i < data.length - 32; i += 4) {
            const qi = data.readFloatLE(i);
            const qk = data.readFloatLE(i + 8);
            if (qi > 0.68 && qi < 0.73 && qk > 0.68 && qk < 0.73 && Math.abs(qi - qk) < 0.005) {
                const qj = data.readFloatLE(i + 4);
                const qr = data.readFloatLE(i + 12);
                if (qj < 0 && qr < 0 && Math.abs(qj - qr) < 0.005) {
                    const rl = Math.sqrt(qi*qi + qj*qj + qk*qk + qr*qr);
                    if (Math.abs(rl - 1.0) < 0.02) {
                        const hz = data.readFloatLE(i - 8);
                        if (hz > 0.7 && hz < 1.5) {
                            console.log(`  Wider match at ${i}: rot=(${qi.toFixed(4)},${qj.toFixed(4)},${qk.toFixed(4)},${qr.toFixed(4)}) hipsZ=${hz.toFixed(6)}`);
                            hipsRotOffsets.push(i);
                        }
                    }
                }
            }
        }
    }
    if (hipsRotOffsets.length === 0) {
        console.log('  WARNING: Could not find Hips rotation pattern');
        return 0;
    }

    let totalMods = 0;

    for (const hipsRotOff of hipsRotOffsets) {
        // Hips Translation is 16 bytes before Rotation
        const hipsTransOff = hipsRotOff - 16;
        if (hipsTransOff < 0) continue;

        // Verify this is Hips: Z should be a reasonable height (0.8 - 1.2)
        const hipsZ = data.readFloatLE(hipsTransOff + 8);
        console.log(`  Checking Hips candidate: transOff=${hipsTransOff} Z=${hipsZ.toFixed(6)}`);
        if (hipsZ < 0.7 || hipsZ > 1.3) continue;

        console.log(`  Found Hips at offset ${hipsTransOff} (Z=${hipsZ.toFixed(6)})`);

        // Root is before Hips. In aPoseLS, Root→Hips gap is 52 bytes.
        // All subsequent bones are 48 bytes apart.
        // But we don't know how many bones are in each array.

        // Better approach: scan forward from Hips, finding each bone's Translation
        // by checking that the rotation (16 bytes after Translation) is a valid quaternion
        // and scale (32 bytes after Translation) is (1,1,1,1)

        // Scale Hips Z (height from ground)
        const newHipsZ = hipsZ * HEIGHT_SCALE;
        data.writeFloatLE(newHipsZ, hipsTransOff + 8);
        console.log(`    Hips Z: ${hipsZ.toFixed(6)} → ${newHipsZ.toFixed(6)}`);
        totalMods++;

        // Now scan forward for more bones.
        // Try both stride 48 and check the data makes sense.
        let currentOff = hipsTransOff + 48;
        let boneIdx = 2; // 0=Root, 1=Hips, 2=Spine...

        while (currentOff + 48 < data.length && boneIdx < 250) {
            // Check if there's a valid quaternion at currentOff + 16
            const ri = data.readFloatLE(currentOff + 16);
            const rj = data.readFloatLE(currentOff + 20);
            const rk = data.readFloatLE(currentOff + 24);
            const rr = data.readFloatLE(currentOff + 28);
            const rotLen = Math.sqrt(ri*ri + rj*rj + rk*rk + rr*rr);

            if (!isFinite(rotLen) || Math.abs(rotLen - 1.0) > 0.02) {
                // Not a valid quaternion — try at +52 (alternate stride)
                const ri2 = data.readFloatLE(currentOff + 20);
                const rj2 = data.readFloatLE(currentOff + 24);
                const rk2 = data.readFloatLE(currentOff + 28);
                const rr2 = data.readFloatLE(currentOff + 32);
                const rotLen2 = Math.sqrt(ri2*ri2 + rj2*rj2 + rk2*rk2 + rr2*rr2);
                if (isFinite(rotLen2) && Math.abs(rotLen2 - 1.0) < 0.02) {
                    currentOff += 4; // adjust to 52-byte stride
                } else {
                    break; // End of array
                }
            }

            // Read Translation X (bone-length direction)
            const tx = data.readFloatLE(currentOff);
            const ty = data.readFloatLE(currentOff + 4);
            const tz = data.readFloatLE(currentOff + 8);

            // Scale the bone-length translation (X) to make V taller
            // X is the primary bone direction in bone-local space
            if (Math.abs(tx) > 0.001) {
                data.writeFloatLE(tx * HEIGHT_SCALE, currentOff);
                totalMods++;
            }

            // Also scale Y slightly (front-back offsets, for proportion)
            if (Math.abs(ty) > 0.001) {
                data.writeFloatLE(ty * HEIGHT_SCALE, currentOff + 4);
            }

            // DON'T scale Z (lateral/width) — keeps shoulders, hips same width
            // DON'T touch Rotation or Scale vectors

            currentOff += 48;
            boneIdx++;
        }

        console.log(`    Processed ${boneIdx} bones in this array`);
    }

    return totalMods;
}

// ─── Archive Rebuilder ───────────────────────────────────────────
function buildArchive(archive, decompressedSegs) {
    const chunks = [];
    let offset = 0;
    const headerBuf = Buffer.alloc(0xA8);
    chunks.push(headerBuf);
    offset += 0xA8;

    const firstSegOffset = archive.segments[0].offset;
    if (firstSegOffset > 0xA8) {
        const customData = Buffer.from(archive.buf.subarray(0xA8, firstSegOffset));
        chunks.push(customData);
        offset += customData.length;
    }

    const newSegments = [];
    for (let si = 0; si < archive.segments.length; si++) {
        const origSeg = archive.segments[si];
        const decompData = decompressedSegs[si];
        let segData;
        if (decompData && (origSeg.zsize !== origSeg.size)) {
            segData = compressToKARK(decompData);
        } else if (decompData) {
            segData = decompData;
        } else {
            segData = Buffer.from(archive.buf.subarray(origSeg.offset, origSeg.offset + origSeg.zsize));
        }
        newSegments.push({ offset, zsize: segData.length, size: decompData ? decompData.length : origSeg.size });
        chunks.push(segData);
        offset += segData.length;
    }

    const dataPad = padToPage(offset);
    if (dataPad > 0) { chunks.push(Buffer.alloc(dataPad)); offset += dataPad; }
    const indexStart = offset;

    const indexBuf = Buffer.alloc(28 + archive.entries.length * 56 + newSegments.length * 16 + archive.deps.length * 8);
    let ipos = 0;
    indexBuf.writeUInt32LE(8, ipos); ipos += 4;
    indexBuf.writeUInt32LE(indexBuf.length - 28 + 8, ipos); ipos += 4;
    indexBuf.writeBigUInt64LE(0n, ipos); ipos += 8;
    indexBuf.writeUInt32LE(archive.entries.length, ipos); ipos += 4;
    indexBuf.writeUInt32LE(newSegments.length, ipos); ipos += 4;
    indexBuf.writeUInt32LE(archive.deps.length, ipos); ipos += 4;
    for (const e of archive.entries) {
        indexBuf.writeBigUInt64LE(e.nameHash, ipos); ipos += 8;
        indexBuf.writeBigInt64LE(e.timestamp, ipos); ipos += 8;
        indexBuf.writeUInt32LE(e.numInline, ipos); ipos += 4;
        indexBuf.writeUInt32LE(e.segStart, ipos); ipos += 4;
        indexBuf.writeUInt32LE(e.segEnd, ipos); ipos += 4;
        indexBuf.writeUInt32LE(e.depStart, ipos); ipos += 4;
        indexBuf.writeUInt32LE(e.depEnd, ipos); ipos += 4;
        e.sha1.copy(indexBuf, ipos); ipos += 20;
    }
    for (const s of newSegments) {
        indexBuf.writeBigUInt64LE(BigInt(s.offset), ipos); ipos += 8;
        indexBuf.writeUInt32LE(s.zsize, ipos); ipos += 4;
        indexBuf.writeUInt32LE(s.size, ipos); ipos += 4;
    }
    for (const d of archive.deps) { indexBuf.writeBigUInt64LE(d, ipos); ipos += 8; }
    chunks.push(indexBuf);
    offset += indexBuf.length;

    const finalPad = padToPage(offset);
    if (finalPad > 0) { chunks.push(Buffer.alloc(finalPad)); offset += finalPad; }

    headerBuf.writeUInt32LE(RDAR_MAGIC, 0);
    headerBuf.writeUInt32LE(archive.header.version, 4);
    headerBuf.writeBigUInt64LE(BigInt(indexStart), 8);
    headerBuf.writeUInt32LE(indexBuf.length, 16);
    headerBuf.writeBigUInt64LE(BigInt(archive.header.debugPosition), 20);
    headerBuf.writeUInt32LE(archive.header.debugSize, 28);
    headerBuf.writeBigUInt64LE(BigInt(offset), 32);
    archive.buf.copy(headerBuf, 40, 40, 0xA8);

    return Buffer.concat(chunks);
}

// ─── Main ────────────────────────────────────────────────────────
function main() {
    const archivePath = path.join(__dirname, '..', 'Unique V Body Shape', 'pc', 'mod', 'zz_johnson_Framework_Unique_V_Body_Shape.archive');

    console.log('============================================');
    console.log('  Unique V Body Shape — Height Scaler');
    console.log(`  Height: ${HEIGHT_SCALE}x taller`);
    console.log('  Width:  unchanged (no shortstack)');
    console.log('  Bones:  same thickness');
    console.log('============================================\n');

    const archive = parseArchive(archivePath);
    console.log(`Archive: ${archive.entries.length} files, ${archive.segments.length} segments\n`);

    const decompressedSegs = [];
    for (let i = 0; i < archive.segments.length; i++) {
        const seg = archive.segments[i];
        try {
            decompressedSegs.push(decompressSegment(archive.buf, seg.offset, seg.zsize, seg.size));
        } catch (e) {
            console.error(`  Segment ${i} error: ${e.message}`);
            decompressedSegs.push(null);
        }
    }

    let totalMods = 0;
    for (let fi = 0; fi < archive.entries.length; fi++) {
        const entry = archive.entries[fi];
        const firstSeg = decompressedSegs[entry.segStart];
        if (!firstSeg) continue;
        const className = getCR2WClassName(firstSeg);
        if (className === 'animRig') {
            const rigType = fi < 8 ? 'male' : 'female';
            console.log(`[${fi}] animRig (${rigType}) — ${entry.nameHash.toString(16).padStart(16,'0')}`);
            const mods = scaleRigForHeight(firstSeg);
            totalMods += mods;
            console.log(`  Total ${mods} bone translations scaled\n`);
        }
    }

    console.log(`\nTotal modifications: ${totalMods}`);
    if (totalMods === 0) { console.log('ERROR: No modifications!'); process.exit(1); }

    console.log('Rebuilding archive...');
    const newArchive = buildArchive(archive, decompressedSegs);
    console.log(`Size: ${archive.buf.length} → ${newArchive.length}`);

    if (Number(newArchive.readBigUInt64LE(32)) !== newArchive.length) {
        console.error('ERROR: Size mismatch!'); process.exit(1);
    }

    fs.writeFileSync(archivePath, newArchive);
    console.log(`Written: ${archivePath}`);
    console.log('\n============================================');
    console.log(`  V is now ${HEIGHT_SCALE}x taller — not a shortstack!`);
    console.log('============================================');
}

main();
