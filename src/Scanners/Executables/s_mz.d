/*
 * s_mz.d : MZ format scanner
 */

module s_mz;

import std.stdio;
import dfile;

private enum ERESWDS = 0x10; /// Reserved words

// DOS 1, 2, 3 .EXE header from newexe.h, Word 1.1a source.
private struct mz_hdr {
	ushort e_magic;        /// Magic number
	ushort e_cblp;         /// Bytes on last page of file
	ushort e_cp;           /// Pages in file
	ushort e_crlc;         /// Relocations
	ushort e_cparh;        /// Size of header in paragraphs
	ushort e_minalloc;     /// Minimum extra paragraphs needed
	ushort e_maxalloc;     /// Maximum extra paragraphs needed
	ushort e_ss;           /// Initial (relative) SS value
	ushort e_sp;           /// Initial SP value
	ushort e_csum;         /// Checksum
	ushort e_ip;           /// Initial IP value
	ushort e_cs;           /// Initial (relative) CS value
	ushort e_lfarlc;       /// File address of relocation table
	ushort e_ovno;         /// Overlay number
	ushort[ERESWDS] e_res; /// Reserved words
	uint   e_lfanew;       /// File address of new exe header, or @0x3c
}

/// Scan a MZ-based executable
void scan_mz() {
    import utils : scpy;
    debug dbg("Started scanning MZ file");

    mz_hdr h;
    scpy(&h, h.sizeof, true);

    with (h) if (e_lfanew) {
        import s_pe : scan_pe;
        import s_le : scan_le;
        import s_ne : scan_ne;
        char[2] sig;
        CurrentFile.seek(e_lfanew); //TODO: if (fseek) -> MZ
        CurrentFile.rawRead(sig);

        switch (sig) {
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
        default:
        }
    }

    report("MZ Executable", false);
    if (h.e_ovno)
        printf(" (Overlay: %d)", h.e_ovno);
    writeln(" for MS-DOS");

    if (More) {
        //printf("e_magic   : %Xh\n", h.e_magic);
        printf("e_cblp    : %Xh\n", h.e_cblp);
        printf("e_cp      : %Xh\n", h.e_cp);
        printf("e_crlc    : %Xh\n", h.e_crlc);
        printf("e_cparh   : %Xh\n", h.e_cparh);
        printf("e_minalloc: %Xh\n", h.e_minalloc);
        printf("e_maxalloc: %Xh\n", h.e_maxalloc);
        printf("e_ss      : %Xh\n", h.e_ss);
        printf("e_sp      : %Xh\n", h.e_sp);
        printf("e_csum    : %Xh\n", h.e_csum);
        printf("e_ip      : %Xh\n", h.e_ip);
        printf("e_cs      : %Xh\n", h.e_cs);
        printf("e_lfarlc  : %Xh\n", h.e_lfarlc);
        printf("e_ovno    : %Xh\n", h.e_ovno);
        printf("e_lfanew  : %Xh\n", h.e_lfanew);
    }
}