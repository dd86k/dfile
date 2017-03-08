/*
 * s_unknown.d : Unknown file formats (with offset)
 */

module s_unknown;

import std.stdio;
import utils;
import dfile;

/// Search for signatures that's not at the beginning of the file.
static void scan_unknown(File file)
{ // Goto instructions are only allowed here.
    import core.stdc.string : memcpy;

    const ulong fl = file.size;

    if (fl > 0x40)
    { // Palm Database Format
        import s_mobi : palmdb_name, scan_palmdoc, scan_mobi;
        enum { // 4 bytes for type, 4 bytes for creator
            ADOBE =      ".pdfADBE",
            BOOKMOBI =   "BOOKMOBI",
            PALMDOC =    "TEXtREAd",
            BDICTY =     "BVokBDIC",
            DB =         "DB99DBOS",
            EREADER0 =   "PNRdPPrs",
            EREADER1 =   "DataPPrs",
            FIREVIEWER = "vIMGView",
            HANDBASE =   "PmDBPmDB",
            INFOVIEW =   "InfoINDB",
            ISILO =      "ToGoToGo",
            ISILO3 =     "SDocSilX",
            JFILE =      "JbDbJBas",
            JFILEPRO =   "JfDbJFil",
            LIST =       "DATALSdb",
            MOBILEDB =   "Mdb1Mdb1",
            PLUCKER =    "DataPlkr",
            QUICKSHEET = "DataSprd",
            SUPERMEMO =  "SM01SMem",
            TEALDOC =    "TEXtTlDc",
            TEALINFO =   "InfoTlIf",
            TEALMEAL =   "DataTlMl",
            TEALPAINT =  "DataTlPt",
            THINKDB =    "dataTDBP",
            TIDES =      "TdatTide",
            TOMERAIDER = "ToRaTRPW",
            WEASEL =     "zTXTGPlm",
            WORDSMITH =  "BDOCWrdS"
        }
        char[8] b;
        file.seek(0x3C);
        file.rawRead(b);
        switch (b)
        {
            case ADOBE:
                report("Palm Database (Adobe Reader)", false);
                palmdb_name(file);
                return;
            case BOOKMOBI:
                scan_mobi(file);
                return;
            case PALMDOC:
                scan_palmdoc(file);
                return;
            case BDICTY:
                report("Palm Database (BDicty)", false);
                palmdb_name(file);
                return;
            case DB:
                report("Palm Database (DB)", false);
                palmdb_name(file);
                return;
            case EREADER0, EREADER1:
                report("Palm Database (eReader)", false);
                palmdb_name(file);
                return;
            case FIREVIEWER:
                report("Palm Database (FireViewer)", false);
                palmdb_name(file);
                return;
            case HANDBASE:
                report("Palm Database (HanDBase)", false);
                palmdb_name(file);
                return;
            case INFOVIEW:
                report("Palm Database (InfoView)", false);
                palmdb_name(file);
                return;
            case ISILO:
                report("Palm Database (iSilo)", false);
                palmdb_name(file);
                return;
            case ISILO3:
                report("Palm Database (iSilo 3)", false);
                palmdb_name(file);
                return;
            case JFILE:
                report("Palm Database (JFile)", false);
                palmdb_name(file);
                return;
            case JFILEPRO:
                report("Palm Database (JFile Pro)", false);
                palmdb_name(file);
                return;
            case LIST:
                report("Palm Database (LIST)", false);
                palmdb_name(file);
                return;
            case MOBILEDB:
                report("Palm Database (MobileDB)", false);
                palmdb_name(file);
                return;
            case PLUCKER:
                report("Palm Database (Plucker)", false);
                palmdb_name(file);
                return;
            case QUICKSHEET:
                report("Palm Database (QuickSheet)", false);
                palmdb_name(file);
                return;
            case SUPERMEMO:
                report("Palm Database (SuperMemo)", false);
                palmdb_name(file);
                return;
            case TEALDOC:
                report("Palm Database (TealDoc)", false);
                palmdb_name(file);
                return;
            case TEALINFO:
                report("Palm Database (TealInfo)", false);
                palmdb_name(file);
                return;
            case TEALMEAL:
                report("Palm Database (TealMeal)", false);
                palmdb_name(file);
                return;
            case TEALPAINT:
                report("Palm Database (TailPaint)", false);
                palmdb_name(file);
                return;
            case THINKDB:
                report("Palm Database (ThinKDB)", false);
                palmdb_name(file);
                return;
            case TIDES:
                report("Palm Database (Tides)", false);
                palmdb_name(file);
                return;
            case TOMERAIDER:
                report("Palm Database (TomeRaider)", false);
                palmdb_name(file);
                return;
            case WEASEL:
                report("Palm Database (Weasel)", false);
                palmdb_name(file);
                return;
            case WORDSMITH:
                report("Palm Database (WordSmith)", false);
                palmdb_name(file);
                return;

            default: // Continue the journey
        }
    }
    else goto CONTINUE;

    if (fl > 0x108)
    { // Tar files
        enum Tar = "ustar\000";
        enum GNUTar = "GNUtar\00";
        char[Tar.length] b;
        file.seek(0x101);
        file.rawRead(b);
        if (b == Tar || b == GNUTar)
        { // http://www.fileformat.info/format/tar/corion.htm
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
            {
                enum s = tar_hdr.sizeof;
                ubyte[s] buf;
                file.rewind();
                file.rawRead(buf);
                memcpy(&h, &buf, s);
            }
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
            return;
        }
    }
    else goto CONTINUE;

    if (fl > 0x9007)
    { // ISO files
        enum ISO = "CD001";
        char[5] b;
        file.seek(0x8001);
        file.rawRead(b);
        if (b == ISO) goto IS_ISO;

        file.seek(0x8801);
        file.rawRead(b);
        if (b == ISO) goto IS_ISO;

        file.seek(0x9001);
        file.rawRead(b);
        if (b == ISO) goto IS_ISO;
        goto NOT_ISO;
IS_ISO:
        {
            report("ISO-9660 CD/DVD image", false);
            enum { // volume type
                T_BOOT = 0,
                T_PRIMARY_VOL_DESC,
                T_SUPP_VOL_DESC,
                T_VOL_PART_DESC,
                T_VOL_TER = 255
            }


            enum s = 2040; // Data, Virtual Sector - 8
            int t;
            char[s] buf;
            bool bootable;
            string label,
            // Informative strings
                system, copyright, publisher, app;
            
            file.seek(0x8000);
            goto ISO_READ;
ISO_P0:
            file.seek(0x8800);
            goto ISO_READ;
ISO_P1:
            file.seek(0x9000);
ISO_READ:
            file.rawRead(buf);
            if (buf[1..6] == ISO)
                switch (buf[0])
                {
                    case T_BOOT: bootable = true; break;
                    case T_PRIMARY_VOL_DESC:
                        label = isostr(buf[40 .. 71]);
                        if (Informing)
                        {
                            system = isostr(buf[8 .. 40]);
                            publisher = isostr(buf[318 .. 446]);
                            app = isostr(buf[574 .. 702]);
                            copyright = isostr(buf[702 .. 739]);
                        }
                        break;
                    default:
                }
            switch (t++) // Dumb system but hey, good stuff.
            {
                case 0:  goto ISO_P0;
                case 1:  goto ISO_P1;
                default: goto ISO_END;
            }
ISO_END:
            if (label)
                write(" \"", label, "\"");
            if (bootable)
                write(", Bootable");
            writeln();

            if (Informing)
            {
                writeln("System: ", system);
                writeln("Publisher: ", publisher);
                writeln("Copyrights: ", copyright);
                writeln("Application: ", app);
            }
            return;
        }
NOT_ISO:
    }
    else goto CONTINUE;

CONTINUE:
    report_unknown();
}