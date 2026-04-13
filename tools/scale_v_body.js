#!/usr/bin/env node
/**
 * Scale V Body Shape — Height Scaler (v3 — fixed padding/CRC)
 *
 * Properly rebuilds archive with 0xD9 padding (matching game format).
 */
const fs = require('fs');
const path = require('path');
const koffi = require('koffi');

const lib = koffi.load(path.join(__dirname, '..', 'WolvenKit.Core', 'lib', 'libkraken.so'));
const Dec = lib.func('int Kraken_Decompress(const uint8_t*,long,uint8_t*,long)');
const Comp = lib.func('int Kraken_Compress(const uint8_t*,long,uint8_t*,int)');

const R = 0x52414452, K = 0x4B52414B;
const HEIGHT_SCALE = 1.1;

// CRC64 ECMA-182 (matching WolvenKit's Crc64.Compute)
const CRC64_TABLE = [
    0x0000000000000000n, 0xb32e4cbe03a75f6fn, 0xf4843657a840a05bn, 0x47aa7ae9abe7ff34n,
    0x7bd0c384ff8f5e33n, 0xc8fe8f3afc28015cn, 0x8f54f5d357cffe68n, 0x3c7ab96d5468a107n,
    0xf7a18709ff1ebc66n, 0x448fcbb7fcb9e309n, 0x0325b15e575e1c3dn, 0xb00bfde054f94352n,
    0x8c71448d0091e255n, 0x3f5f08330336bd3an, 0x78f572daa8d1420en, 0xcbdb3e64ab761d61n,
    0x7d9ba13851336649n, 0xceb5ed8652943926n, 0x891f976ff973c612n, 0x3a31dbd1fad4997dn,
    0x064b62bcaebc387an, 0xb5652e02ad1b6715n, 0xf2cf54eb06fc9821n, 0x41e11855055bc74en,
    0x8a3a2631ae2dda2fn, 0x39146a8fad8a8540n, 0x7ebe1066066d7a74n, 0xcd905cd805ca251bn,
    0xf1eae5b551a2841cn, 0x42c4a90b5205db73n, 0x056ed3e2f9e22447n, 0xb6409f5cfa457b28n,
    0xfb374270a266cc92n, 0x48190ecea1c193fdn, 0x0fb374270a266cc9n, 0xbc9d3899098133a6n,
    0x80e781f45de992a1n, 0x33c9cd4a5e4ecdcen, 0x7463b7a3f5a932fan, 0xc74dfb1df60e6d95n,
    0x0c96c5795d7870f4n, 0xbfb889c75edf2f9bn, 0xf812f32ef538d0afn, 0x4b3cbf90f69f8fc0n,
    0x774606fda2f72ec7n, 0xc4684a43a15071a8n, 0x83c230aa0ab78e9cn, 0x30ec7c140910d1f3n,
    0x86ace348f355aadbn, 0x3582aff6f0f2f5b4n, 0x7228d51f5b150a80n, 0xc10699a158b255efn,
    0xfd7c20cc0cdaf4e8n, 0x4e526c720f7dab87n, 0x09f8169ba49a54b3n, 0xbad65a25a73d0bdcn,
    0x710d64410c4b16bdn, 0xc22328ff0fec49d2n, 0x85895216a40bb6e6n, 0x36a71ea8a7ace989n,
    0x0adda7c5f3c4488en, 0xb9f3eb7bf06317e1n, 0xfe5991925b84e8d5n, 0x4d77dd2c5823b7ban,
    0x64b62bcaebc387a1n, 0xd7986774e864d8cen, 0x90321d9d438327fan, 0x231c512340247895n,
    0x1f66e84e144cd992n, 0xac48a4f017eb86fdn, 0xebe2de19bc0c79c9n, 0x58cc92a7bfab26a6n,
    0x9317acc314dd3bc7n, 0x2039e07d177a64a8n, 0x67939a94bc9d9b9cn, 0xd4bdd62abf3ac4f3n,
    0xe8c76f47eb5265f4n, 0x5be923f9e8f53a9bn, 0x1c4359104312c5afn, 0xaf6d15ae40b59ac0n,
    0x192d8af2baf0e1e8n, 0xaa03c64cb957be87n, 0xeda9bca512b041b3n, 0x5e87f01b11171edcn,
    0x62fd4976457fbfdbn, 0xd1d305c846d8e0b4n, 0x96797f21ed3f1f80n, 0x2557339fee9840efn,
    0xee8c0dfb45ee5d8en, 0x5da24145464902e1n, 0x1a083bacedaefdd5n, 0xa9267712ee09a2ban,
    0x955cce7fba6103bdn, 0x267282c1b9c65cd2n, 0x61d8f8281221a3e6n, 0xd2f6b4961186fc89n,
    0x9f8169ba49a54b33n, 0x2caf25044a02145cn, 0x6b055fede1e5eb68n, 0xd82b1353e242b407n,
    0xe451aa3eb62a1500n, 0x577fe680b58d4a6fn, 0x10d59c691e6ab55bn, 0xa3fbd0d71dcdea34n,
    0x6820eeb3b6bbf755n, 0xdb0ea20db51ca83an, 0x9ca4d8e41efb570en, 0x2f8a945a1d5c0861n,
    0x13f02d374934a966n, 0xa0de61894a93f609n, 0xe7741b60e174093dn, 0x545a57dee2d35652n,
    0xe21ac88218962d7an, 0x5134843c1b317215n, 0x169efed5b0d68d21n, 0xa5b0b26bb371d24en,
    0x99ca0b06e7197349n, 0x2ae447b8e4be2c26n, 0x6d4e3d514f59d312n, 0xde6071ef4cfe8c7dn,
    0x15bb4f8be788911cn, 0xa6950335e42fce73n, 0xe13f79dc4fc83147n, 0x521135624c6f6e28n,
    0x6e6b8c0f1807cf2fn, 0xdd45c0b11ba09040n, 0x9aefba58b0476f74n, 0x29c1f6e6b3e0301bn,
    0xc96c5795d7870f42n, 0x7a421b2bd420502dn, 0x3de861c27fc7af19n, 0x8ec62d7c7c60f076n,
    0xb2bc941128085171n, 0x0192d8af2baf0e1en, 0x4638a2468048f12an, 0xf516eef883efae45n,
    0x3ecdd09c2899b324n, 0x8de39c222b3eec4bn, 0xca49e6cb80d9137fn, 0x7967aa75837e4c10n,
    0x451d1318d716ed17n, 0xf6335fa6d4b1b278n, 0xb199254f7f564d4cn, 0x02b769f17cf11223n,
    0xb4f7f6ad86b4690bn, 0x07d9ba1385133664n, 0x4073c0fa2ef4c950n, 0xf35d8c442d53963fn,
    0xcf273529793b3738n, 0x7c0979977a9c6857n, 0x3ba3037ed17b9763n, 0x888d4fc0d2dcc80cn,
    0x435671a479aad56dn, 0xf0783d1a7a0d8a02n, 0xb7d247f3d1ea7536n, 0x04fc0b4dd24d2a59n,
    0x3886b22086258b5en, 0x8ba8fe9e8582d431n, 0xcc0284772e652b05n, 0x7f2cc8c92dc2746an,
    0x325b15e575e1c3d0n, 0x8175595b76469cbfn, 0xc6df23b2dda1638bn, 0x75f16f0cde063ce4n,
    0x498bd6618a6e9de3n, 0xfaa59adf89c9c28cn, 0xbd0fe036222e3db8n, 0x0e21ac88218962d7n,
    0xc5fa92ec8aff7fb6n, 0x76d4de52895820d9n, 0x317ea4bb22bfdfedn, 0x8250e80521188082n,
    0xbe2a516875702185n, 0x0d041dd676d77eean, 0x4aae673fdd3081den, 0xf9802b81de97deb1n,
    0x4fc0b4dd24d2a599n, 0xfceef8632775faf6n, 0xbb44828a8c9205c2n, 0x086ace348f355aadn,
    0x34107759db5dfbaan, 0x873e3be7d8faa4c5n, 0xc094410e731d5bf1n, 0x73ba0db070ba049en,
    0xb86133d4dbcc19ffn, 0x0b4f7f6ad86b4690n, 0x4ce50583738cb9a4n, 0xffcb493d702be6cbn,
    0xc3b1f050244347ccn, 0x709fbcee27e418a3n, 0x3735c6078c03e797n, 0x841b8ab98fa4b8f8n,
    0xadda7c5f3c4488e3n, 0x1ef430e13fe3d78cn, 0x595e4a08940428b8n, 0xea7006b697a377d7n,
    0xd60abfdbc3cbd6d0n, 0x6524f365c06c89bfn, 0x228e898c6b8b768bn, 0x91a0c532682c29e4n,
    0x5a7bfb56c35a3485n, 0xe955b7e8c0fd6bean, 0xaeffcd016b1a94den, 0x1dd181bf68bdcbb1n,
    0x21ab38d23cd56ab6n, 0x9285746c3f7235d9n, 0xd52f0e859495caedn, 0x6601423b97329582n,
    0xd041dd676d77eeaan, 0x636f91d96ed0b1c5n, 0x24c5eb30c5374ef1n, 0x97eba78ec690119en,
    0xab911ee392f8b099n, 0x18bf525d915feff6n, 0x5f1528b43ab810c2n, 0xec3b640a391f4fadn,
    0x27e05a6e926952ccn, 0x94ce16d091ce0da3n, 0xd3646c393a29f297n, 0x604a2087398eadf8n,
    0x5c3099ea6de60cffn, 0xef1ed5546e415390n, 0xa8b4afbdc5a6aca4n, 0x1b9ae303c601f3cbn,
    0x56ed3e2f9e224471n, 0xe5c372919d851b1en, 0xa26908783662e42an, 0x114744c635c5bb45n,
    0x2d3dfdab61ad1a42n, 0x9e13b115620a452dn, 0xd9b9cbfcc9edba19n, 0x6a978742ca4ae576n,
    0xa14cb926613cf817n, 0x1262f598629ba778n, 0x55c88f71c97c584cn, 0xe6e6c3cfcadb0723n,
    0xda9c7aa29eb3a624n, 0x69b2361c9d14f94bn, 0x2e184cf536f3067fn, 0x9d36004b35545910n,
    0x2b769f17cf112238n, 0x9858d3a9ccb67d57n, 0xdff2a94067518263n, 0x6cdce5fe64f6dd0cn,
    0x50a65c93309e7c0bn, 0xe388102d33392364n, 0xa4226ac498dedc50n, 0x170c267a9b79833fn,
    0xdcd7181e300f9e5en, 0x6ff954a033a8c131n, 0x28532e49984f3e05n, 0x9b7d62f79be8616an,
    0xa707db9acf80c06dn, 0x14299724cc279f02n, 0x5383edcd67c06036n, 0xe0ada17364673f59n
];

function crc64(buf) {
    let crc = 0xFFFFFFFFFFFFFFFFn;
    for (let j = 0; j < buf.length; j++) {
        crc = (crc >> 8n) ^ CRC64_TABLE[Number((crc ^ BigInt(buf[j])) & 0xFFn)];
    }
    return ~crc & 0xFFFFFFFFFFFFFFFFn;
}

function padPage(size) { const r = size % 4096; return r === 0 ? 0 : 4096 - r; }
function d9pad(len) { const b = Buffer.alloc(len, 0xD9); return b; }

function getCls(d) {
    if (d.length < 0xA2 || d[0]!==0x43||d[1]!==0x52||d[2]!==0x32||d[3]!==0x57) return null;
    let e = 0xA1; while (e < d.length && e < 0x200 && d[e]) e++;
    return d.toString('utf8', 0xA1, e);
}

function scaleRig(data) {
    let mods = 0;
    for (let i = 16; i < data.length - 32; i += 4) {
        const qi = data.readFloatLE(i), qk = data.readFloatLE(i+8);
        if (qi > 0.68 && qi < 0.73 && qk > 0.68 && qk < 0.73 && Math.abs(qi-qk) < 0.005) {
            const qj = data.readFloatLE(i+4), qr = data.readFloatLE(i+12);
            if (qj < -0.01 && qr < -0.01 && Math.abs(qj-qr) < 0.005) {
                const rl = Math.sqrt(qi*qi+qj*qj+qk*qk+qr*qr);
                if (Math.abs(rl-1) < 0.02) {
                    const hz = data.readFloatLE(i-8);
                    if (hz < 0.7 || hz > 1.5) continue;
                    // Scale Hips Z
                    data.writeFloatLE(hz * HEIGHT_SCALE, i-8);
                    console.log(`    Hips Z: ${hz.toFixed(4)} → ${(hz*HEIGHT_SCALE).toFixed(4)}`);
                    mods++;
                    // Scale subsequent bones
                    let off = i - 16 + 48, cnt = 0;
                    while (off + 48 < data.length && cnt < 250) {
                        const ri=data.readFloatLE(off+16),rj=data.readFloatLE(off+20),rk=data.readFloatLE(off+24),rr=data.readFloatLE(off+28);
                        if (!isFinite(Math.sqrt(ri*ri+rj*rj+rk*rk+rr*rr)) || Math.abs(Math.sqrt(ri*ri+rj*rj+rk*rk+rr*rr)-1) > 0.02) break;
                        const tx = data.readFloatLE(off);
                        if (Math.abs(tx) > 0.001) { data.writeFloatLE(tx*HEIGHT_SCALE, off); mods++; }
                        const ty = data.readFloatLE(off+4);
                        if (Math.abs(ty) > 0.001) data.writeFloatLE(ty*HEIGHT_SCALE, off+4);
                        off += 48; cnt++;
                    }
                    console.log(`    Scaled ${cnt+1} bones`);
                }
            }
        }
    }
    return mods;
}

function main() {
    const archPath = path.join(__dirname, '..', 'Unique V Body Shape', 'pc', 'mod', 'zz_johnson_Framework_Unique_V_Body_Shape.archive');
    console.log(`Height Scale: ${HEIGHT_SCALE}x\n`);

    const orig = fs.readFileSync(archPath);
    if (orig.readUInt32LE(0) !== R) throw new Error('Not RDAR');

    // Parse index
    const ip = Number(orig.readBigUInt64LE(8));
    let p = ip; p+=4+4+8;
    const fec=orig.readUInt32LE(p);p+=4; const fsc=orig.readUInt32LE(p);p+=4; const rdc=orig.readUInt32LE(p);p+=4;

    const entries = [];
    for (let i=0;i<fec;i++){
        const nh=orig.readBigUInt64LE(p);p+=8;const ts=orig.readBigInt64LE(p);p+=8;
        const ni=orig.readUInt32LE(p);p+=4;const ss=orig.readUInt32LE(p);p+=4;
        const se=orig.readUInt32LE(p);p+=4;const ds=orig.readUInt32LE(p);p+=4;
        const de=orig.readUInt32LE(p);p+=4;const sha=Buffer.from(orig.subarray(p,p+20));p+=20;
        entries.push({nh,ts,ni,ss,se,ds,de,sha});
    }
    const segs = [];
    for (let i=0;i<fsc;i++){
        const o=Number(orig.readBigUInt64LE(p));p+=8;
        const z=orig.readUInt32LE(p);p+=4;const s=orig.readUInt32LE(p);p+=4;
        segs.push({o,z,s});
    }
    const deps = [];
    for (let i=0;i<rdc;i++){deps.push(orig.readBigUInt64LE(p));p+=8;}

    console.log(`${fec} files, ${fsc} segments\n`);

    // Decompress all
    const rawSegs = segs.map(seg => {
        if (seg.z === seg.s) return Buffer.from(orig.subarray(seg.o, seg.o+seg.s));
        if (orig.readUInt32LE(seg.o) === K) {
            const sz = orig.readUInt32LE(seg.o+4);
            const c = Buffer.from(orig.subarray(seg.o+8, seg.o+seg.z));
            const out = Buffer.alloc(sz); Dec(c, c.length, out, sz); return out;
        }
        throw new Error('Not KARK');
    });

    // Modify animRig files
    let totalMods = 0;
    for (let fi=0;fi<fec;fi++){
        const e = entries[fi];
        const d = rawSegs[e.ss];
        if (getCls(d) !== 'animRig') continue;
        console.log(`[${fi}] animRig (${fi<8?'male':'female'})`);
        totalMods += scaleRig(d);
    }
    if (!totalMods) { console.log('No mods!'); process.exit(1); }
    console.log(`\nTotal: ${totalMods} modifications\n`);

    // Recompress all
    const compSegs = rawSegs.map((raw, i) => {
        if (segs[i].z === segs[i].s) return raw;
        if (raw.length <= 256) return raw;
        const out = Buffer.alloc(raw.length + 2048);
        const r = Comp(raw, raw.length, out, 4);
        if (r <= 0 || raw.length <= r+8) return raw;
        const result = Buffer.alloc(8+r);
        result.writeUInt32LE(K, 0);
        result.writeUInt32LE(raw.length, 4);
        out.copy(result, 8, 0, r);
        return result;
    });

    // Rebuild archive with CORRECT 0xD9 padding
    const firstOff = segs[0].o;
    const headerArea = Buffer.from(orig.subarray(0, firstOff));

    const newSegs = [];
    let wo = firstOff;
    const segBufs = [];
    for (let i=0;i<compSegs.length;i++){
        newSegs.push({o:wo, z:compSegs[i].length, s:rawSegs[i].length});
        segBufs.push(compSegs[i]);
        wo += compSegs[i].length;
    }

    // 0xD9 padding to page boundary
    const dp = padPage(wo);
    wo += dp;
    const ixStart = wo;

    // Build index
    const tcSize = 4+4+4 + fec*56 + fsc*16 + rdc*8;
    const ixSize = 4+4+8 + tcSize;
    const ixBuf = Buffer.alloc(ixSize);
    let ip2 = 0;
    ixBuf.writeUInt32LE(8, ip2); ip2+=4;
    ixBuf.writeUInt32LE(tcSize+8, ip2); ip2+=4;
    // CRC64 placeholder — compute after writing table content
    const crcOffset = ip2; ip2+=8;
    ixBuf.writeUInt32LE(fec, ip2); ip2+=4;
    ixBuf.writeUInt32LE(fsc, ip2); ip2+=4;
    ixBuf.writeUInt32LE(rdc, ip2); ip2+=4;

    for (const e of entries){
        ixBuf.writeBigUInt64LE(e.nh, ip2); ip2+=8;
        ixBuf.writeBigInt64LE(e.ts, ip2); ip2+=8;
        ixBuf.writeUInt32LE(e.ni, ip2); ip2+=4;
        ixBuf.writeUInt32LE(e.ss, ip2); ip2+=4;
        ixBuf.writeUInt32LE(e.se, ip2); ip2+=4;
        ixBuf.writeUInt32LE(e.ds, ip2); ip2+=4;
        ixBuf.writeUInt32LE(e.de, ip2); ip2+=4;
        e.sha.copy(ixBuf, ip2); ip2+=20;
    }
    for (const s of newSegs){
        ixBuf.writeBigUInt64LE(BigInt(s.o), ip2); ip2+=8;
        ixBuf.writeUInt32LE(s.z, ip2); ip2+=4;
        ixBuf.writeUInt32LE(s.s, ip2); ip2+=4;
    }
    for (const d of deps){ ixBuf.writeBigUInt64LE(d, ip2); ip2+=8; }

    // Compute CRC64 over the table content (everything after CRC field)
    const tableData = ixBuf.subarray(16, ip2); // skip fileTableOffset(4)+fileTableSize(4)+CRC(8)
    const computedCrc = crc64(tableData);
    ixBuf.writeBigUInt64LE(computedCrc, crcOffset);
    console.log(`CRC64: ${computedCrc.toString(16)}`);

    wo += ixSize;
    const fp = padPage(wo);
    wo += fp;

    // Update header
    headerArea.writeBigUInt64LE(BigInt(ixStart), 8);
    headerArea.writeUInt32LE(ixSize, 16);
    headerArea.writeBigUInt64LE(BigInt(wo), 32);

    const output = Buffer.concat([
        headerArea, ...segBufs,
        d9pad(dp),  // 0xD9 padding (not 0x00!)
        ixBuf,
        d9pad(fp)   // 0xD9 final padding
    ]);

    console.log(`Original: ${orig.length} → New: ${output.length}`);

    // Verify bit-identity for unmodified segments
    let segDiffs = 0;
    for (let i=0;i<newSegs.length;i++){
        const origData = orig.subarray(segs[i].o, segs[i].o+segs[i].z);
        const newData = output.subarray(newSegs[i].o, newSegs[i].o+newSegs[i].z);
        if (!origData.equals(newData)) segDiffs++;
    }
    console.log(`Segments changed: ${segDiffs}/${fsc} (should be 2 — the animRig files)`);

    fs.writeFileSync(archPath, output);
    console.log(`\nWritten: ${archPath}`);
    console.log(`V is now ${HEIGHT_SCALE}x taller!`);
}

main();
