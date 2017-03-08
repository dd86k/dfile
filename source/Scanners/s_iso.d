/*
 * s_iso.d : ISO file scanner
 */

module s_iso;

import std.stdio, dfile, utils;

enum ISO = "CD001";

void scan_iso(File file)
{
    enum { // volume type
        BOOT = 0,
        PRIMARY_VOL_DESC,
        SUPP_VOL_DESC,
        VOL_PART_DESC,
        VOL_TER = 255
    }
    enum s = 1024; // Half the data
    int t;
    char[s] buf;
    bool bootable;
    string label,
    // Informative strings
        system, copyright, publisher, app, abst, biblio,
        ctime, mtime, etime, eftime;
    
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
            case BOOT: bootable = true; break;
            case PRIMARY_VOL_DESC:
                label = isostr(buf[40 .. 71]);
                if (Informing)
                {
                    system = isostr(buf[8 .. 40]);
                    publisher = isostr(buf[318 .. 446]);
                    app = isostr(buf[574 .. 702]);
                    copyright = isostr(buf[702 .. 739]);
                    abst = isostr(buf[739 .. 776]);
                    biblio = isostr(buf[776 .. 813]);
                    ctime = isostr(buf[813 .. 830]);
                    mtime = isostr(buf[830 .. 847]);
                    etime = isostr(buf[847 .. 864]);
                    eftime = isostr(buf[864 .. 881]);
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
        writeln("Abstract Identifier: ", abst);
        writeln("Bibliographic: ", biblio);
        writeln("Created: ",
            ctime[0..4], "/", ctime[4..6], "/", ctime[6..8], " ",
            ctime[8..10], ":", ctime[10..12], ":", ctime[12..14], ".",
            ctime[14..16], "+", ctime[16] * 15);
        writeln("Modified: ",
            mtime[0..4], "/", mtime[4..6], "/", mtime[6..8],
            mtime[8..10], ":", mtime[10..12], ":", mtime[12..14], ".",
            mtime[14..16], "+", mtime[16] * 15);
        writeln("Expires: ",
            etime[0..4], "/", etime[4..6], "/", etime[6..8],
            etime[8..10], ":", etime[10..12], ":", etime[12..14], ".",
            etime[14..16], "+", etime[16] * 15);
        writeln("Effective at: ",
            eftime[0..4], "/", eftime[4..6], "/", eftime[6..8],
            eftime[8..10], ":", eftime[10..12], ":", eftime[12..14], ".",
            eftime[14..16], "+", eftime[16] * 15);
    }
}