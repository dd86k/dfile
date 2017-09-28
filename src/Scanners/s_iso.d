/*
 * s_iso.d : ISO file scanner
 */

module s_iso;

import core.stdc.stdio;
import std.stdio : write, writeln;
import dfile : More, report, fp;
import utils;

enum ISO = "CD001"; /// ISO signature
private enum BLOCK_SIZE = 1024; // Half an ISO block, buffer

/// Scan an ISO file
void scan_iso()
{
    string
        // PRIMARY_VOL_DESC
        label, system, voliden,
        copyright, publisher, app, abst, biblio,
        ctime, mtime, etime, eftime,
        // BOOT
        bootsysiden, bootiden;
    bool bootable;
    long volume_size;
    enum { // volume type
        BOOT = 0,
        PRIMARY_VOL_DESC,
        /*SUPP_VOL_DESC,
        VOL_PART_DESC,
        VOL_TER = 255*/
    }

    void scan_block(char* buf) {
        switch (*buf) {
        case BOOT:
            bootable = true;
            if (More)
            {
                bootsysiden = isostr(buf[7 .. 39]);
                bootiden = isostr(buf[39 .. 71]);
            }
            break;
        case PRIMARY_VOL_DESC:
            label = isostr(buf[40 .. 71]);
            // size * blocksize
            volume_size = *cast(uint*)(&buf[80]) * *cast(ushort*)(&buf[128]);
            if (More)
            {
                system = isostr(buf[8 .. 40]);
                voliden = isostr(buf[190 .. 318]);
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
    }
    /// Returns: Returns true to stop.
    bool check_seek(long pos, char* buf) {
        // OKAY to cast to int since we only check up to ~9000H
        if (fseek(fp, cast(int)pos, SEEK_SET)) return true;
        fread(buf, BLOCK_SIZE, 1, fp);
        if (buf[1..6] == ISO) scan_block(buf);
        return false;
    }
    string isodate(string stamp) {
        import std.format : format;
        return format("%s-%s-%s %s:%s:%s.%s+%d",
            stamp[0..4], stamp[4..6], stamp[6..8], stamp[8..10],
            stamp[10..12], stamp[12..14], stamp[14..16], stamp[16] * 15);
    }
    char[BLOCK_SIZE] buf;
    char* bufp = &buf[0];

    if (check_seek(0x8000, bufp)) goto ISO_DONE;
    if (check_seek(0x8800, bufp)) goto ISO_DONE;
    if (check_seek(0x9000, bufp)) goto ISO_DONE;

ISO_DONE:
    report("ISO-9660 CD/DVD image", false);
    if (label) write(` "`, label, `"`);
    if (volume_size) write(", ", formatsize(volume_size));
    if (bootable) write(", Bootable");
    writeln;

    if (More)
    {
        writeln("Boot System Identifier: ", bootsysiden);
        writeln("Boot Identifier: ", bootiden);
        writeln("System: ", system);
        writeln("Volume Set Indentifier: ", voliden);
        writeln("Publisher: ", publisher);
        writeln("Copyrights: ", copyright);
        writeln("Application: ", app);
        writeln("Abstract Identifier: ", abst);
        writeln("Bibliographic: ", biblio);
        writeln("Created: ", isodate(ctime));
        writeln("Modified: ", isodate(mtime));
        writeln("Expires: ", isodate(etime));
        writeln("Effective at: ", isodate(eftime));
    }
}