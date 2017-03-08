/*
 * s_iso.d : ISO file scanner
 */

module s_iso;

import std.stdio, dfile, utils;

enum ISO = "CD001";

void scan_iso(File file)
{
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
    report("ISO-9660 CD/DVD image", false);
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
}