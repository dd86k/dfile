module s_mz;

/*
 * MZ format scanner
 */

import std.stdio;
import dfile;
import s_pe;
import s_le;
import s_ne;

static void scan_mz(File file)
{
    if (_debug)
        writefln("L%04d: Started scanning MZ file", __LINE__);

    uint header_offset;
    {
        int[1] b;
        file.seek(0x3c, 0);
        file.rawRead(b);
        header_offset = b[0];

        if (_debug)
            writefln("L%04d: Header Offset: %X", __LINE__, header_offset);

        file.seek(header_offset, 0);
        ubyte[2] pesig;
        file.rawRead(pesig);

        if (header_offset)
            switch (cast(string)pesig)
            {
            case "PE":
                file.seek(header_offset, 0);
                scan_pe(file);
                return;

            case "NE":
                file.seek(header_offset, 0);
                scan_ne(file);
                return;

            case "LE": case "LX": // LE/LX
                file.seek(header_offset, 0);
                scan_le(file);
                return;

            default: break;
            }
    }

    report("MZ MS-DOS Exectutable");
}