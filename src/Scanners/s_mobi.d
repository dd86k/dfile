/*
 * s_mobi.d : Mobi ebook file scanner
 */

module s_mobi;

import std.stdio, dfile, utils;
import core.stdc.stdio;

private enum STARTPOS = 944;

private struct palmdoc_hdr {
    ushort Compression;
    ushort Reserved;
    uint TextLength;
    ushort RecordCount, RecordSize;
    union {
        uint CurrentPosition;
        struct { // MOBI
            ushort Encryption, Reversed;
        }
    }
}

private struct mobi_hdr
{
    char[4] Identifier; // "MOBI"
    uint HeaderLength, Type, Encoding, UniqueID, FileVersion;
    // ...
}

/// Get PalmDB name
void palmdb_name() {
    char[32] name;
    char* p = &name[0];
    rewind(fp);
    fread(p, 32, 1, fp);
    printf(" \"%s\"\n", p);
}

/// Scan PalmDB file
void scan_palmdoc() {
    palmdoc_hdr h;
    fread(&h, h.sizeof, 1, fp);

    report("Palm Document", false);

    if (h.Compression == 0x0100) // Big Endian
        write(", PalmDOC compressed");
    else if (h.Compression == 0x4844) // 17480
        write(", HUFF/CDIC compressed");

    palmdb_name();
}

/// Scan a MOBI file
void scan_mobi() { // Big endian
    palmdoc_hdr h;
    mobi_hdr mh;
    fseek(fp, STARTPOS, SEEK_SET);
    fread(&h, h.sizeof, 1, fp);
    fread(&mh, mh.sizeof, 1, fp);

    report("Mobipocket ", false);

    switch (mh.Type) {
        case 0xE800_0000, 0x0200_0000: // 232, 2
            write("ebook");
            break;
        case 0x0300_0000: // 3
            write("PalmDoc ebook");
            break;
        case 0x0400_0000: // 4
            write("audio");
            break;
        case 0xF800_0000: // 248
            write("KF8");
            break;
        case 0x0101_0000: // 257
            write("News");
            break;
        case 0x0201_0000: // 258
            write("News feed");
            break;
        case 0x0301_0000: // 259
            write("News magazine");
            break;
        case 0x0102_0000: // 513
            write("PICS");
            break;
        case 0x0202_0000: // 514
            write("WORD");
            break;
        case 0x0302_0000: // 515
            write("XLS");
            break;
        case 0x0402_0000: // 516
            write("PPT");
            break;
        case 0x0502_0000: // 517
            write("TEXT");
            break;
        case 0x0602_0000: // 518
            write("HTML");
            break;
        default:
            write("Unknown");
            break;
    }

    write(" file");

    if (h.Compression == 0x0100)
        write(", PalmDOC compressed");
    else if (h.Compression == 0x4844)
        write(", HUFF/CDIC compressed");

    if (h.Encryption == 0x0100)
        write(", Legacy Mobipocket encryption");
    else if (h.Encryption == 0x0200)
        write(", Mobipocket encryption");

    palmdb_name();
}