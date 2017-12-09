/*
 * s_mz.d : MZ format scanner
 */

module s_mz;

import core.stdc.stdio;
import dfile;

private enum ERESWDS = 0x10; /// Reserved words

// DOS 1, 2, 3 .EXE header from newexe.h, Word 1.1a source.
/// MZ Header
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
	uint   e_lfanew;       /// File address of new exe header (usually at 3Ch)
}

/// Scan a MZ-based executable
void scan_mz() {
    debug dbg("Started scanning MZ file");

    if (fseek(fp, 0x3c, SEEK_SET)) {
        report_unknown; // Because by then we went past the header
        return;
    }
    uint p;
    fread(&p, 4, 1, fp);

    if (p) {
        import s_pe : scan_pe;
        import s_le : scan_le;
        import s_ne : scan_ne;
        ushort sig;
        if (fseek(fp, p, SEEK_SET)) { // Should it report as MZ?
            report_unknown;
            return;
        }
        fread(&sig, 2, 1, fp);

        switch (sig) {
        case 0x4550: // "PE"
            scan_pe;
            return;
        case 0x454E: // "NE"
            scan_ne;
            return;
        case 0x454C, 0x584C: // "LE", "LX"
            fseek(fp, p, SEEK_SET); // for signature printing
            scan_le;
            return;
        default:
        }
    }

    mz_hdr h;
    rewind(fp);
    fread(&h, h.sizeof, 1, fp);

    report("MZ executable for MS-DOS", false);
    if (h.e_ovno)
        printf(" (Overlay: %d)", h.e_ovno);
    printf("\n");

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