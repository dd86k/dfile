/*
 * s_unknown.d : Unknown file formats (with offset)
 */

module s_unknown;

import std.stdio;
import dfile;

private enum BYTE_LIMIT = 1024 * 16;

static void scan_unknown(File file)
{
    // Scan by offsets.
    /*case "CD00": // Offset: 0x8001, 0x8801, 0x9001
        {
            char[1] b;
            file.rawRead(b);
            switch (b)
            {
                case ['1']:
                    report("ISO9660 CD/DVD image file (ISO)");
                    break;
                default:
                    report_unknown(file);
                    break;
            }
        }
        break;*/

    /*case "usta": // Tar offset 0x101
        {

        }
        break;*/

    // Scan for readable characters for n (16KB?) bytes and at least
    // n (3?) readable characters
    throw new Exception("TODO: scan_unknown");
}