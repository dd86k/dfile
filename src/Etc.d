/*
 * s_unknown.d : Unknown file formats (with offset)
 */

module Etc;

import std.stdio : File;
import dfile;
import core.stdc.stdio : fseek, FILE, SEEK_SET;

/// Search for signatures that's not at the beginning of the file.
/// Params: file = File structure.
void scan_etc()
{
    if (fseek(fp, 0x3C, SEEK_SET) == 0)
    { // Palm Database Format
        import s_mobi : palmdb_name, scan_palmdoc, scan_mobi;
        enum { // 4 bytes for type, 4 bytes for creator
            ADOBE =      ".pdfADBE", BOOKMOBI =   "BOOKMOBI",
            PALMDOC =    "TEXtREAd", BDICTY =     "BVokBDIC",
            DB =         "DB99DBOS", EREADER0 =   "PNRdPPrs",
            EREADER1 =   "DataPPrs", FIREVIEWER = "vIMGView",
            HANDBASE =   "PmDBPmDB", INFOVIEW =   "InfoINDB",
            ISILO =      "ToGoToGo", ISILO3 =     "SDocSilX",
            JFILE =      "JbDbJBas", JFILEPRO =   "JfDbJFil",
            LIST =       "DATALSdb", MOBILEDB =   "Mdb1Mdb1",
            PLUCKER =    "DataPlkr", QUICKSHEET = "DataSprd",
            SUPERMEMO =  "SM01SMem", TEALDOC =    "TEXtTlDc",
            TEALINFO =   "InfoTlIf", TEALMEAL =   "DataTlMl",
            TEALPAINT =  "DataTlPt", THINKDB =    "dataTDBP",
            TIDES =      "TdatTide", TOMERAIDER = "ToRaTRPW",
            WEASEL =     "zTXTGPlm", WORDSMITH =  "BDOCWrdS"
        }
        char[8] b;
        CurrentFile.rawRead(b);
        switch (b)
        {
            case ADOBE:
                report("Palm Database (Adobe Reader)", false);
                palmdb_name();
                return;
            case BOOKMOBI: scan_mobi(); return;
            case PALMDOC:  scan_palmdoc(); return;
            case BDICTY:
                report("Palm Database (BDicty)", false);
                palmdb_name();
                return;
            case DB:
                report("Palm Database (DB)", false);
                palmdb_name();
                return;
            case EREADER0, EREADER1:
                report("Palm Database (eReader)", false);
                palmdb_name();
                return;
            case FIREVIEWER:
                report("Palm Database (FireViewer)", false);
                palmdb_name();
                return;
            case HANDBASE:
                report("Palm Database (HanDBase)", false);
                palmdb_name();
                return;
            case INFOVIEW:
                report("Palm Database (InfoView)", false);
                palmdb_name();
                return;
            case ISILO:
                report("Palm Database (iSilo)", false);
                palmdb_name();
                return;
            case ISILO3:
                report("Palm Database (iSilo 3)", false);
                palmdb_name();
                return;
            case JFILE:
                report("Palm Database (JFile)", false);
                palmdb_name();
                return;
            case JFILEPRO:
                report("Palm Database (JFile Pro)", false);
                palmdb_name();
                return;
            case LIST:
                report("Palm Database (LIST)", false);
                palmdb_name();
                return;
            case MOBILEDB:
                report("Palm Database (MobileDB)", false);
                palmdb_name();
                return;
            case PLUCKER:
                report("Palm Database (Plucker)", false);
                palmdb_name();
                return;
            case QUICKSHEET:
                report("Palm Database (QuickSheet)", false);
                palmdb_name();
                return;
            case SUPERMEMO:
                report("Palm Database (SuperMemo)", false);
                palmdb_name();
                return;
            case TEALDOC:
                report("Palm Database (TealDoc)", false);
                palmdb_name();
                return;
            case TEALINFO:
                report("Palm Database (TealInfo)", false);
                palmdb_name();
                return;
            case TEALMEAL:
                report("Palm Database (TealMeal)", false);
                palmdb_name();
                return;
            case TEALPAINT:
                report("Palm Database (TailPaint)", false);
                palmdb_name();
                return;
            case THINKDB:
                report("Palm Database (ThinKDB)", false);
                palmdb_name();
                return;
            case TIDES:
                report("Palm Database (Tides)", false);
                palmdb_name();
                return;
            case TOMERAIDER:
                report("Palm Database (TomeRaider)", false);
                palmdb_name();
                return;
            case WEASEL:
                report("Palm Database (Weasel)", false);
                palmdb_name();
                return;
            case WORDSMITH:
                report("Palm Database (WordSmith)", false);
                palmdb_name();
                return;

            default: // Continue the journey
        }
    }
    else goto CONTINUE;

    if (fseek(fp, 0x101, SEEK_SET) == 0)
    { // Tar files
        import s_tar : scan_tar, Tar, GNUTar;
        char[Tar.length] b;
        CurrentFile.rawRead(b);
        if (b == Tar || b == GNUTar) {
            scan_tar();
            return;
        }
    }
    else goto CONTINUE;

    if (fseek(fp, 0x8001, SEEK_SET) == 0)
    { // ISO files
        import s_iso : scan_iso, ISO;
        char[5] b;
        CurrentFile.rawRead(b);
        if (b == ISO) goto IS_ISO;

        if (fseek(fp, 0x8801, SEEK_SET)) goto CONTINUE;
        CurrentFile.rawRead(b);
        if (b == ISO) goto IS_ISO;

        if (fseek(fp, 0x9001, SEEK_SET)) goto CONTINUE;
        CurrentFile.rawRead(b);
        if (b == ISO) goto IS_ISO;
        goto NOT_ISO;
IS_ISO:
        scan_iso();
        return;
NOT_ISO:
    }
    else goto CONTINUE;

CONTINUE:
    report_unknown();
}