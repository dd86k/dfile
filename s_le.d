module s_le;

import std.stdio;
import dfile;

private struct LE_HEADER
{
    ubyte[2] Signature; // "LX" or "LE"
    ubyte ByteOrder;
    ubyte WordOrder;
    uint FormatLevel;
    ushort CPUType;
    ushort OSType;
    uint ModuleVersion;
    uint ModuleFlags;
    // And these are the most interesting parts.
}

static void scan_le(File file)
{
    LE_HEADER peh;
    {
        import core.stdc.string;
        ubyte[LE_HEADER.sizeof] buf;
        file.rawRead(buf);
        memcpy(&peh, &buf, LE_HEADER.sizeof);
    }

    writef("%s: %s ", file.name, peh.Signature);

    if (peh.ModuleFlags & 0x8000)
        write("Libary module");
    else
        write("Program module");

    write(" (");

    switch (peh.OSType)
    {
    default:
        write("Unknown");
        break;
    case 1:
        write("OS/2");
        break;
    case 2:
        write("Windows");
        break;
    case 3:
        write("DOS 4.x");
        break;
    case 4:
        write("Windows 386");
        break;
    }

    write("), ");

    switch (peh.CPUType)
    {
    default:
        write("unknown");
        break;
    case 1:
        write("Intel 80286");
        break;
    case 2:
        write("Intel 80386");
        break;
    case 3:
        write("Intel 80486");
        break;
    }

    writeln(" CPU and up");
}