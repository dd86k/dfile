module s_le;

import std.stdio;
import dfile;

/*
 * LE/LX format scanner
 */

private struct e32_hdr
{
    char[2] e32_magic; // "LX" or "LE"
    ubyte e32_border; // Byte order
    ubyte e32_worder; // Word order
    uint e32_level;   // LE/LX Version
    ushort e32_cpu;   // CPU
    ushort e32_os;    // OS
    uint e32_ver;     // Module version
    uint e32_mflags;  // Module flags
    uint e32_mpages;  // # Module pages
    uint e32_startobj;// Object # for IP
    uint e32_eip;     // Extended IP
    // And these are the most interesting parts.
}

private const enum : ushort {
    OS2 = 1,
    Windows,
    DOS4,
    Windows386
}

private const enum : ushort {
    i286 = 1,
    i386,
    i486
}

private const enum : uint {
    Library = 0x8000,
    ProtectedMemoryLibrary = 0x18000,
    PhysicalDeviceDriver = 0x20000,
    VirtualDeiveDriver = 0x28000
}

static void scan_le(File file)
{
    e32_hdr h;
    {
        import core.stdc.string;
        ubyte[e32_hdr.sizeof] buf;
        file.rawRead(buf);
        memcpy(&h, &buf, e32_hdr.sizeof);
    }

    if (_debug || _more)
    {
        writefln("LE e32_magic : %s",  h.e32_magic);
        writefln("LE e32_border: %Xh", h.e32_border);
        writefln("LE e32_worder: %Xh", h.e32_worder);
        writefln("LE e32_level : %Xh", h.e32_level);
        writefln("LE e32_cpu   : %Xh", h.e32_cpu);
        writefln("LE e32_os    : %Xh", h.e32_os);
        writefln("LE e32_ver   : %Xh", h.e32_ver);
        writefln("LE e32_mflags: %Xh", h.e32_mflags);  // Module flags
    }

    writef("%s: %s ", file.name, h.e32_magic);

    if (h.e32_mflags & Library)
        write("Libary module");
    else if (h.e32_mflags & ProtectedMemoryLibrary)
        write("Protected Memory Library module");
    else if (h.e32_mflags & PhysicalDeviceDriver)
        write("Physical Device Driver module");
    else if (h.e32_mflags & VirtualDeiveDriver)
        write("Virtual Device Driver module");
    else
        write("Executable"); // Program module

    write(" (");

    switch (h.e32_os)
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

    switch (h.e32_cpu)
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

    write(h.e32_border ? "B-BE " : "B-LE ");
    write(h.e32_worder ? "W-BE " : "W-LE ");

    writeln();
}