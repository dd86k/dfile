/*
 * s_ne.d : New Executable format scanner
 */

module s_ne;

import std.stdio;
import dfile;
import utils;

// New .EXE header, found in newexe.h in the Word 1.1a source.
private struct ne_hdr
{
    char[2]  ne_magic;       /* Magic number NE_MAGIC */
	char     ne_ver;         /* Version number */
	char     ne_rev;         /* Revision number */
	ushort   ne_enttab;      /* Offset of Entry Table */
	ushort   ne_cbenttab;    /* Number of bytes in Entry Table */
	uint     ne_crc;         /* Checksum of whole file */
	ushort   ne_flags;       /* Flag word */
	ushort   ne_autodata;    /* Automatic data segment number */
	ushort   ne_heap;        /* Initial heap allocation */
	ushort   ne_stack;       /* Initial stack allocation */
	uint     ne_csip;        /* Initial CS:IP setting */
	uint     ne_sssp;        /* Initial SS:SP setting */
	ushort   ne_cseg;        /* Count of file segments */
	ushort   ne_cmod;        /* Entries in Module Reference Table */
	ushort   ne_cbnrestab;   /* Size of non-resident name table */
	ushort   ne_segtab;      /* Offset of Segment Table */
	ushort   ne_rsrctab;     /* Offset of Resource Table */
	ushort   ne_restab;      /* Offset of resident name table */
	ushort   ne_modtab;      /* Offset of Module Reference Table */
	ushort   ne_imptab;      /* Offset of Imported Names Table */
	uint     ne_nrestab;     /* Offset of Non-resident Names Table */
	ushort   ne_cmovent;     /* Count of movable entries */
	ushort   ne_align;       /* Segment alignment shift count */
	ushort   ne_cres;        /* Count of resource segments */
	ushort   ne_psegcsum;    /* offset to segment chksums */
	ushort   ne_pretthunks;  /* offset to return thunks */
	ushort   ne_psegrefbytes;/* offset to segment ref. bytes */
	ushort   ne_swaparea;    /* Minimum code swap area size */
    ubyte[2] ne_expver;      /* Expected Windows version number */
}

private enum {
    NENOTP = 0x8000, /* Not a process */
    NENONC = 0x4000, /* Non-conforming program */
    NEIERR = 0x2000, /* Errors in image */
    NEPROT = 0x0008, /* Runs in protected mode */
    NEREAL = 0x0004, /* Runs in real mode */
    NEINST = 0x0002, /* Instance data */
    NESOLO = 0x0001  /* Solo data */
}

/// Scan a NE executable
void scan_ne() {
    ne_hdr h;
    fread(&h, h.sizeof, 1, fp);

    report("NE ", false);

    if (h.ne_flags & NENOTP)
        write("DLL or driver");
    else
        write("Executable");

    write(" file");

    if (h.ne_expver[0])
        printf(", Windows %d.%d expected", h.ne_expver[1], h.ne_expver[0]);

    if (h.ne_flags)
    {
        if (h.ne_flags & NENONC)
            write(", non-conforming program");
        if (h.ne_flags & NEIERR)
            write(", errors in image");
        if (h.ne_flags & NEPROT)
            write(", runs in protected mode");
        if (h.ne_flags & NEREAL)
            write(", runs in real mode");
        if (h.ne_flags & NEINST)
            write(", instance data");
        if (h.ne_flags & NESOLO)
            write(", solo data");
    }

    writeln;

    if (More) {
        printf("ne_magic       : %s\n", &h.ne_magic[0]);
        printf("ne_ver         : %Xh\n", h.ne_ver);
        printf("ne_rev         : %Xh\n", h.ne_rev);
        printf("ne_enttab      : %Xh\n", h.ne_enttab);
        printf("ne_cbenttab    : %Xh\n", h.ne_cbenttab);
        printf("ne_crc         : %Xh\n", h.ne_crc);
        printf("ne_flags       : %Xh\n", h.ne_flags);
        printf("ne_autodata    : %Xh\n", h.ne_autodata);
        printf("ne_heap        : %Xh\n", h.ne_heap);
        printf("ne_stack       : %Xh\n", h.ne_stack);
        printf("ne_csip        : %Xh\n", h.ne_csip);
        printf("ne_sssp        : %Xh\n", h.ne_sssp);
        printf("ne_cseg        : %Xh\n", h.ne_cseg);
        printf("ne_cmod        : %Xh\n", h.ne_cmod);
        printf("ne_cbnrestab   : %Xh\n", h.ne_cbnrestab);
        printf("ne_segtab      : %Xh\n", h.ne_segtab);
        printf("ne_rsrctab     : %Xh\n", h.ne_rsrctab);
        printf("ne_restab      : %Xh\n", h.ne_restab);
        printf("ne_modtab      : %Xh\n", h.ne_modtab);
        printf("ne_imptab      : %Xh\n", h.ne_imptab);
        printf("ne_nrestab     : %Xh\n", h.ne_nrestab);
        printf("ne_cmovent     : %Xh\n", h.ne_cmovent);
        printf("ne_align       : %Xh\n", h.ne_align);
        printf("ne_cres        : %Xh\n", h.ne_cres);
        printf("ne_psegcsum    : %Xh\n", h.ne_psegcsum);
        printf("ne_pretthunks  : %Xh\n", h.ne_pretthunks);
        printf("ne_psegrefbytes: %Xh\n", h.ne_psegrefbytes);
        printf("ne_swaparea    : %Xh\n", h.ne_swaparea);
        printf("%X %X\n", h.ne_expver[0], h.ne_expver[1]);
        writeln;
    }
}
