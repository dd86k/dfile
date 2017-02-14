/*
 * s_mobi.d : Mobi ebook file scanner
 */

module s_mobi;

import std.stdio;
import dfile;

private struct palmdoc_hdr
{
    ushort Compression;
    ushort Reserved;
    uint TextLength;
    ushort RecordCount, RecordSize;
    union {
        uint CurrentPosition;
        struct {
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

void palmdb_name(File file)
{
    char[32] name;
    file.rewind();
    file.rawRead(name);
    char* p = name.ptr;
    size_t n;
    while (*p++ != '\0') ++n;
    writefln(` "%s"`, name[0..n]);
}

void scan_mobi(File file)
{
    palmdoc_hdr h;
    mobi_hdr mh;
    {
        import core.stdc.string;
        ubyte[palmdoc_hdr.sizeof] b;
        ubyte[mobi_hdr.sizeof] b1;
        file.seek(86);
        file.rawRead(b);
        file.rawRead(b1);
        memcpy(&h, &b, palmdoc_hdr.sizeof);
        memcpy(&mh, &b1, mobi_hdr.sizeof);
    }

    if (ShowingName)
        writef("%s: ", file.name);

    write("Mobipocket ");

    switch (mh.Type)
    {
        case 232, 2:
            write("ebook");
            break;
        case 3:
            write("PalmDoc ebook");
            break;
        case 4:
            write("audio");
            break;
        case 248:
            write("KF8");
            break;
        case 257:
            write("News");
            break;
        case 258:
            write("News feed");
            break;
        case 259:
            write("News magazine");
            break;
        case 513:
            write("PICS");
            break;
        case 514:
            write("WORD");
            break;
        case 515:
            write("XLS");
            break;
        case 516:
            write("PPT");
            break;
        case 517:
            write("TEXT");
            break;
        case 518:
            write("HTML");
            break;
        default:
            write("Unknown");
            break;
    }

    write(" file");

    if (h.Compression == 1)
        write(", PalmDOC compressed");
    else if (h.Compression == 17480)
        write(", HUFF/CDIC compressed");

    if (h.Encryption == 1)
        write(", Legacy Mobipocket encrypted");
    else if (h.Encryption == 2)
        write(", Mobipocket encrypted");

    palmdb_name(file);
}