/*
 * s_tar.d : Tar archive scanner
 */

module s_tar;

import std.stdio, dfile, utils;

enum Tar = "ustar\000";
enum GNUTar = "GNUtar\00";

void scan_tar(File file)
{ // http://www.fileformat.info/format/tar/corion.htm
    import core.stdc.string : memcpy;
    enum NAMSIZ = 100;
    enum TUNMLEN = 32, TGNMLEN = 32;
    struct tar_hdr {
        char[NAMSIZ] name;
        char[8] mode;
        char[8] uid;
        char[8] gid;
        char[12] size;
        char[12] mtime;
        char[8] chksum;
        char    linkflag;
        char[NAMSIZ] linkname;
        char[8] magic;
        char[TUNMLEN] uname;
        char[TGNMLEN] gname;
        char[8] devmajor;
        char[8] devminor;
    }

    tar_hdr h;
    structcpy(file, &h, h.sizeof, true);

    if (Informing)
    {
        switch (h.linkflag)
        {
            case 0,'0': report("Normal", false); break;
            case '1': report("Link", false); break;
            case '2': report("Syslink", false); break;
            case '3': report("Character Special", false); break;
            case '4': report("Block Special", false); break;
            case '5': report("Directory", false); break;
            case '6': report("FIFO Special", false); break;
            case '7': report("Contiguous", false); break;
            default:  report("Unknown type Tar archive"); return;
        }
        writeln(" Tar archive, Reports ", tarstr(h.size), " Bytes");
    }
    else report("Tar archive");
}