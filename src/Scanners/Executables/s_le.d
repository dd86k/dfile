/*
 * LE/LX format scanner
 */

module s_le;

import std.stdio;
import dfile;
import utils;
import std.string : format;

private struct e32_hdr {
    char[2] e32_magic; // "LX" or "LE"
    ubyte e32_border;  // Byte order
    ubyte e32_worder;  // Word order
    uint e32_level;    // LE/LX Version
    ushort e32_cpu;    // CPU
    ushort e32_os;     // OS
    uint e32_ver;      // Module version
    uint e32_mflags;   // Module flags
    uint e32_mpages;   // # Module pages
    uint e32_startobj; // Object # for IP
    uint e32_eip;      // Extended IP
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

/// Scan a LE executable
void scan_le() {
    e32_hdr h;
    fread(&h, h.sizeof, 1, fp);

    if (More) {
        printf("e32_magic : %s\n", &h.e32_magic[0]);
        printf("e32_border: %Xh\n", h.e32_border);
        printf("e32_worder: %Xh\n", h.e32_worder);
        printf("e32_level : %Xh\n", h.e32_level);
        printf("e32_cpu   : %Xh\n", h.e32_cpu);
        printf("e32_os    : %Xh\n", h.e32_os);
        printf("e32_ver   : %Xh\n", h.e32_ver);
        printf("e32_mflags: %Xh\n", h.e32_mflags);  // Module flags
    }

    report(cast(immutable)h.e32_magic, false);

    switch (h.e32_os) {
    default: write(" Unknown "); break;
    case OS2: write(" OS/2 "); break;
    case Windows: write(" Windows "); break;
    case DOS4: write(" DOS 4.x "); break;
    case Windows386: write(" Windows 386 "); break;
    }

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

    write(" for ");

    switch (h.e32_cpu) {
    default: write("Unknown"); break;
    case i286: write("i286"); break;
    case i386: write("i386"); break;
    case i486: write("i486"); break;
    }

    write(" machines, ");

    write(h.e32_border ? "BE" : "LE");
    write(" Byte order, ");
    write(h.e32_worder ? "BE" : "LE");
    write(" Word order");

    writeln();
}