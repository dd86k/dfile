/*
 * s_unknown.d : Unknown file formats (with offset)
 */

module s_unknown;

import std.stdio;
import dfile : report;

private enum BYTE_LIMIT = 1024 * 16;

static void scan_unknown(File file)
{
    import core.stdc.string;
    // Scan by offsets.

    {
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
    
    {
        enum ISO = "CD0001";
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

    //TODO: Scan for readable characters for n (16KB?) bytes and at least n
    //      (3?) readable characters.
}