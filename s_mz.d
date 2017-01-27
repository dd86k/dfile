module s_mz;

/*
 * MZ format scanner
 */

import std.stdio;
import dfile;
import s_pe;
import s_le;
import s_ne;

private const size_t ERESWDS = 0x10;
//private const size_t ENEWh = 0x3C;

// DOS 1, 2, 3 .EXE header from newexe.h, Word 1.1a source.
private struct mz_hdr
{
	ushort e_magic;        /* Magic number */
	ushort e_cblp;         /* Bytes on last page of file */
	ushort e_cp;           /* Pages in file */
	ushort e_crlc;         /* Relocations */
	ushort e_cparh;      /* Size of header in paragraphs */
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
	uint   e_lfanew;       /* File address of new exe header */
};

static void scan_mz(File file)
{
    if (_debug)
        writefln("L%04d: Started scanning MZ file", __LINE__);

    mz_hdr h;
    {
        import core.stdc.string;
        byte[mz_hdr.sizeof] buf;
        file.rewind();
        file.rawRead(buf);
        memcpy(&h, &buf, mz_hdr.sizeof);
    }

    if (_debug || _more)
    {
        writefln("MZ e_magic   : %Xh", h.e_magic);
        writefln("MZ e_cblp    : %Xh", h.e_magic);
        writefln("MZ e_cp      : %Xh", h.e_cp);
        writefln("MZ e_crlc    : %Xh", h.e_crlc);
        writefln("MZ e_cparh   : %Xh", h.e_cparh);
        writefln("MZ e_minalloc: %Xh", h.e_minalloc);
        writefln("MZ e_maxalloc: %Xh", h.e_maxalloc);
        writefln("MZ e_ss      : %Xh", h.e_ss);
        writefln("MZ e_sp      : %Xh", h.e_sp);
        writefln("MZ e_csum    : %Xh", h.e_csum);
        writefln("MZ e_ip      : %Xh", h.e_ip);
        writefln("MZ e_cs      : %Xh", h.e_cs);
        writefln("MZ e_lfarlc  : %Xh", h.e_lfarlc);
        writefln("MZ e_ovno    : %Xh", h.e_ovno);
        writefln("MZ e_lfanew  : %Xh", h.e_lfanew);
    }

    if (h.e_lfanew)
    {
        file.seek(h.e_lfanew);
        char[2] pesig;
        file.rawRead(pesig);

        switch (pesig)
        {
        case "PE":
            file.seek(h.e_lfanew);
            scan_pe(file);
            return;

        case "NE":
            file.seek(h.e_lfanew);
            scan_ne(file);
            return;

        case "LE": case "LX": // LE/LX
            file.seek(h.e_lfanew);
            scan_le(file);
            return;

        default: break;
        }
    }

    writef("%s: MZ Executable", file.name);

    if (h.e_ovno)
        writef(" (Overlay: %Xh)", h.e_ovno);

    writeln(" for MS-DOS");
}