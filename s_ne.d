module s_ne;

import std.stdio;
import dfile;

/*
 * New Executable format scanner
 */

private struct ne_hdr
{
    char[2] ne_magic;       /* Magic number NE_MAGIC */
	char    ne_ver;         /* Version number */
	char    ne_rev;         /* Revision number */
	ushort  ne_enttab;      /* Offset of Entry Table */
	ushort  ne_cbenttab;    /* Number of bytes in Entry Table */
	uint    ne_crc;         /* Checksum of whole file */
	ushort  ne_flags;       /* Flag word */
	ushort  ne_autodata;    /* Automatic data segment number */
	ushort  ne_heap;        /* Initial heap allocation */
	ushort  ne_stack;       /* Initial stack allocation */
	uint    ne_csip;        /* Initial CS:IP setting */
	uint    ne_sssp;        /* Initial SS:SP setting */
	ushort  ne_cseg;        /* Count of file segments */
	ushort  ne_cmod;        /* Entries in Module Reference Table */
	ushort  ne_cbnrestab;   /* Size of non-resident name table */
	ushort  ne_segtab;      /* Offset of Segment Table */
	ushort  ne_rsrctab;     /* Offset of Resource Table */
	ushort  ne_restab;      /* Offset of resident name table */
	ushort  ne_modtab;      /* Offset of Module Reference Table */
	ushort  ne_imptab;      /* Offset of Imported Names Table */
	uint    ne_nrestab;     /* Offset of Non-resident Names Table */
	ushort  ne_cmovent;     /* Count of movable entries */
	ushort  ne_align;       /* Segment alignment shift count */
	ushort  ne_cres;        /* Count of resource segments */
	ushort  ne_psegcsum;    /* offset to segment chksums */
	ushort  ne_pretthunks;  /* offset to return thunks */
	ushort  ne_psegrefbytes;/* offset to segment ref. bytes */
	ushort  ne_swaparea;    /* Minimum code swap area size */
	ushort  ne_expver;      /* Expected Windows version number */
}

const ushort NENOTP = 0x8000; /* Not a process */
const ushort NENONC = 0x4000; /* Non-conforming program */
const ushort NEIERR = 0x2000; /* Errors in image */
const ushort NEPROT = 0x0008; /* Runs in protected mode */
const ushort NEREAL = 0x0004; /* Runs in real mode */
const ushort NEINST = 0x0002; /* Instance data */
const ushort NESOLO = 0x0001; /* Solo data */

static void scan_ne(File file)
{
    ne_hdr peh;
    {
        import core.stdc.string;
        ubyte[ne_hdr.sizeof] buf;
        file.rawRead(buf);
        memcpy(&peh, &buf, ne_hdr.sizeof);
    }

    if (_debug)
    {
        writefln("NE ne_flags: %X", peh.ne_flags);
    }

    writef("%s: %s ", file.name, peh.ne_magic);

    if (peh.ne_flags & NENOTP)
        write("DLL or driver");
    else
        write("Executable");

    if (peh.ne_flags)
    {
        if (peh.ne_flags & NENONC)
            write(", non-conforming program");
        if (peh.ne_flags & NEIERR)
            write(", errors in image");
        if (peh.ne_flags & NEPROT)
            write(", runs in protected mode");
        if (peh.ne_flags & NEREAL)
            write(", runs in real mode");
        if (peh.ne_flags & NEINST)
            write(", instance data");
        if (peh.ne_flags & NESOLO)
            write(", solo data");
    }

    writeln();
}
