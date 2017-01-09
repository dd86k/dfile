module s_ne;

import std.stdio;
import dfile;

/*
 * NE format scanner
 */

private struct NE_HEADER
{
    ubyte[2] Signature; // "NE"
    ubyte MajLinkerVersion;
    ubyte MinLinkerVersion;
    ushort EntryTableOffset;
    ushort EntryTableLength;
    uint FileLoadCRC;
    ubyte ProgFlags;
    ubyte ApplFlags;
    ubyte AutoDataSegIndex;
    ushort InitHeapSize;
    ushort InitStackSize;
    uint EntryPoint;
    uint InitStack;
    ushort SegCount;
    ushort ModRefs;
    ushort NoResNamesTabSiz;
    ushort SegTableOffset;
    ushort ResTableOffset;
    ushort ResidNamTable;
    ushort ModRefTable;
    ushort ImportNameTable;
    uint OffStartNonResTab;
    ushort MovEntryCount;
    ushort FileAlnSzShftCnt;
    ushort nResTabEntries;
    ubyte targOS;
}

static void scan_ne(File file)
{
    NE_HEADER peh;
    {
        import core.stdc.string;
        ubyte[NE_HEADER.sizeof] buf;
        file.rawRead(buf);
        memcpy(&peh, &buf, peh.sizeof);
    }

    writef("%s: NE ", file.name);

    if (peh.ApplFlags & 0x80)
        write("DLL/Driver");
    else
        write("Executable");

    write(" (");

    switch (peh.targOS)
    {
        default: case 0:
            write("Unknown");
            break;
        case 1:
            write("OS/2");
            break;
        case 2:
            write("Windows");
            break;
        case 3:
            write("European MS-DOS 4.x");
            break;
        case 4:
            write("Windows 386");
            break;
        case 5:
            write("BOSS");
            break;
    }

    write(") with ");
    
    if (peh.ProgFlags & 0x80)
        write("80x87");
    else if (peh.ProgFlags & 0x40)
        write("80386");
    else if (peh.ProgFlags & 0x20)
        write("80286");
    else if (peh.ProgFlags & 0x10)
        write("8086");
    else
        write("unknown");
        
    writeln(" instructions");
}