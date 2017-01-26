module s_mz;

/*
 * MZ format scanner
 */

import std.stdio;
import dfile;
import s_pe;
import s_le;
import s_ne;

const size_t ERESWDS = 0x10;
//const size_t ENEWHDR = 0x3C;

// DOS 1, 2, 3 .EXE header from newexe.h, Word 1.1a source.
struct mz_hdr
{
	ushort e_magic;        /* Magic number */
	ushort e_cblp;         /* Bytes on last page of file */
	ushort e_cp;           /* Pages in file */
	ushort e_crlc;         /* Relocations */
	ushort e_cparhdr;      /* Size of header in paragraphs */
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

    mz_hdr exe_hdr;
    {
        import core.stdc.string;

        byte[mz_hdr.sizeof] buf;
        file.rewind();
        file.rawRead(buf);
        memcpy(&exe_hdr, &buf, mz_hdr.sizeof);
    }

    if (_debug || _more)
    {
        writefln("MZ e_magic : %Xh", exe_hdr.e_magic);
        writefln("MZ e_csum  : %Xh", exe_hdr.e_csum);
        writefln("MZ e_lfanew: %Xh", exe_hdr.e_lfanew);
    }

    if (exe_hdr.e_lfanew)
    {
        file.seek(exe_hdr.e_lfanew, 0);
        ubyte[2] pesig;
        file.rawRead(pesig);

        switch (cast(string)pesig)
        {
        case "PE":
            file.seek(exe_hdr.e_lfanew, 0);
            scan_pe(file);
            return;

        case "NE":
            file.seek(exe_hdr.e_lfanew, 0);
            scan_ne(file);
            return;

        case "LE": case "LX": // LE/LX
            file.seek(exe_hdr.e_lfanew, 0);
            scan_le(file);
            return;

        default: break;
        }
    }

    writefln("%s: MZ Exectutable, %d pages, %d relocations",
        file.name, exe_hdr.e_cp, exe_hdr.e_crlc);
}