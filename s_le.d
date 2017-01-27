module s_le;

import std.stdio;
import dfile;

/*
 * LE/LX format scanner
 */

private struct LE_HEADER
{
    char[2] Signature; // "LX" or "LE"
    ubyte ByteOrder;
    ubyte WordOrder;
    uint FormatLevel;
    ushort CPUType;
    ushort OSType;
    uint ModuleVersion;
    uint ModuleFlags;
    // And these are the most interesting parts.
}

private enum {
    OS2 = 1,
    Windows,
    DOS4,
    Windows386
}

private enum {
    i286 = 1,
    i386,
    i486
}

static void scan_le(File file)
{
    LE_HEADER h;
    {
        import core.stdc.string;
        ubyte[LE_HEADER.sizeof] buf;
        file.rawRead(buf);
        memcpy(&h, &buf, LE_HEADER.sizeof);
    }

    //TODO: Do _more option.

    writef("%s: %s ", file.name, h.Signature);

/*
    00000000h = Program module.
    00008000h = Library module.
    00018000h = Protected Memory Library module.
    00020000h = Physical Device Driver module.
    00028000h = Virtual Device Driver module.
*/
    if (h.ModuleFlags & 0x8000)
        write("Libary module");
    else if (h.ModuleFlags & 0x18000)
        write("Protected Memory Library module");
    else if (h.ModuleFlags & 0x20000)
        write("Physical Device Driver module");
    else if (h.ModuleFlags & 0x28000)
        write("Virtual Device Driver module");
    else
        write("Executable");

    write(" (");

    switch (h.OSType)
    {
    default:
        write("Unknown");
        break;
    case OS2:
        write("OS/2");
        break;
    case Windows:
        write("Windows");
        break;
    case DOS4:
        write("DOS 4.x");
        break;
    case Windows386:
        write("Windows 386");
        break;
    }

    write("), ");

    switch (h.CPUType)
    {
    default:
        write("Unknown");
        break;
    case i286:
        write("Intel 80286");
        break;
    case i386:
        write("Intel 80386");
        break;
    case i486:
        write("Intel 80486");
        break;
    }

    write(" CPUs, ");

    write(h.ByteOrder ? "B-BE " : "B-LE ");
    write(h.WordOrder ? "B-BE " : "B-LE ");

    writeln();
}