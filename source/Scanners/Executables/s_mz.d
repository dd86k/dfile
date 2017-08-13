/*
 * s_mz.d : MZ format scanner
 */

module s_mz;

import std.stdio;
import dfile;

private enum ERESWDS = 0x10;

// DOS 1, 2, 3 .EXE header from newexe.h, Word 1.1a source.
private struct mz_hdr
{
	ushort e_magic;        /* Magic number */
	ushort e_cblp;         /* Bytes on last page of file */
	ushort e_cp;           /* Pages in file */
	ushort e_crlc;         /* Relocations */
	ushort e_cparh;        /* Size of header in paragraphs */
	ushort e_minalloc;     /* Minimum extra paragraphs needed */
	ushort e_maxalloc;     /* Maximum extra paragraphs needed */
	ushort e_ss;           /* Initial (relative) SS value */
	ushort e_sp;           /* Initial SP value */
	ushort e_csum;         /* Checksum */
	ushort e_ip;           /* Initial IP value */
	ushort e_cs;           /* Initial (relative) CS value */
	ushort e_lfarlc;       /* File address of relocation table */
	ushort e_ovno;         /* Overlay number */
	ushort[ERESWDS] e_res; /* Reserved words */
	uint   e_lfanew;       /* File address of new exe header, or @0x3c */
}

void scan_mz()
{
    import utils : scpy;
    debug dbg("Started scanning MZ file");

    int e_lfanew;
    {
        int[1] buf;
        CurrentFile.seek(0x3C);
        CurrentFile.rawRead(buf);
        e_lfanew = buf[0];
    }

    if (e_lfanew)
    {
        import s_pe : scan_pe;
        import s_le : scan_le;
        import s_ne : scan_ne;
        CurrentFile.seek(e_lfanew);
        char[2] sig;
        CurrentFile.rawRead(sig);

        switch (sig)
        {
        case "PE":
            CurrentFile.seek(e_lfanew);
            scan_pe();
            return;

        case "NE":
            CurrentFile.seek(e_lfanew);
            scan_ne();
            return;

        case "LE", "LX":
            CurrentFile.seek(e_lfanew);
            scan_le();
            return;

        default: break;
        }
    }

    mz_hdr h;
    scpy(CurrentFile, &h, h.sizeof, true);

    if (More)
    {
        writefln("e_magic   : %Xh", h.e_magic);
        writefln("e_cblp    : %Xh", h.e_cblp);
        writefln("e_cp      : %Xh", h.e_cp);
        writefln("e_crlc    : %Xh", h.e_crlc);
        writefln("e_cparh   : %Xh", h.e_cparh);
        writefln("e_minalloc: %Xh", h.e_minalloc);
        writefln("e_maxalloc: %Xh", h.e_maxalloc);
        writefln("e_ss      : %Xh", h.e_ss);
        writefln("e_sp      : %Xh", h.e_sp);
        writefln("e_csum    : %Xh", h.e_csum);
        writefln("e_ip      : %Xh", h.e_ip);
        writefln("e_cs      : %Xh", h.e_cs);
        writefln("e_lfarlc  : %Xh", h.e_lfarlc);
        writefln("e_ovno    : %Xh", h.e_ovno);
        writefln("e_lfanew  : %Xh", h.e_lfanew);
    }

    report("MZ Executable", false);

    if (h.e_ovno)
        writef(" (Overlay: %d)", h.e_ovno);

    writeln(" for MS-DOS");
}