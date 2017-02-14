/*
 * s_unknown.d : Unknown file formats (with offset)
 */

module s_unknown;

import std.stdio;
import dfile;

//private enum BYTE_LIMIT = 1024 * 16;

static void scan_unknown(File file)
{
    import core.stdc.string : memcpy;
    // Scan by offsets.

    //ulong fs = file.tell;

    { // Tar files
        enum Tar = "usta";
        char[4] b;
        file.seek(0x101);
        file.rawRead(b);
        if (b == Tar)
        {
            report("Tar file");
            return;
        }
    }
    
    { // ISO files
        enum ISO = "CD001";
        char[5] b0, b1, b2;
        file.seek(0x8001);
        file.rawRead(b0);
        file.seek(0x8801);
        file.rawRead(b1);
        file.seek(0x9001);
        file.rawRead(b2);
        if (b0 == ISO || b1 == ISO || b2 == ISO)
        {
            report("ISO9660 CD/DVD image file (ISO)");
            return;
        }
    }

    { // Palm Database Format
        import s_mobi;
        enum { // 4 bytes for type, 4 bytes for creator
            ADOBE = ".pdfADBE",
            BOOKMOBI = "BOOKMOBI",
            PALMDOC = "TEXtREAd",
            BDICTY = "BVokBDIC",
            DB = "DB99DBOS",
            EREADER0 = "PNRdPPrs",
            EREADER1 = "DataPPrs",
            FIREVIEWER = "vIMGView",
            HANDBASE = "PmDBPmDB",
            INFOVIEW = "InfoINDB",
            ISILO = "ToGoToGo",
            ISILO3 = "SDocSilX",
            JFILE = "JbDbJBas",
            JFILEPRO = "JfDbJFil",
            LIST = "DATALSdb",
            MOBILEDB = "Mdb1Mdb1",
            PLUCKER = "DataPlkr",
            QUICKSHEET = "DataSprd",
            SUPERMEMO = "SM01SMem",
            TEALDOC = "TEXtTlDc",
            TEALINFO = "InfoTlIf",
            
        }
        char[8] b;
        file.seek(0x3C);
        file.rawRead(b);
        switch (b)
        {
            case ADOBE:
                report("Palm Database (Adobe Reader)");
                break;
            case BOOKMOBI:
                file.seek(0x3c);
                scan_mobi(file);
                return;
            case PALMDOC:
                report("Palm Database (PalmDOC)");
                break;
            default: // Continue the journey
        }
    }

    if (ShowingName)
        writef("%s: ", file.name);

    writeln("Unknown file type.");

    //TODO: Scan for readable characters for n (16KB?) bytes and at least n
    //      (3?) readable characters.
}