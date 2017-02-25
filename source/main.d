module dfile;

import std.stdio;
import std.file : exists, isDir;
import std.string : format;
import core.stdc.string : memcpy;

import s_elf : scan_elf;
import s_fatelf : scan_fatelf;
import s_mz : scan_mz;
import s_pe : scan_pe;
import s_ne : scan_ne;
import s_le : scan_le;
import s_mach : scan_mach;
import s_unknown : scan_unknown;

enum {
    PROJECT_NAME = "dfile",
    PROJECT_VERSION = "0.2.0"
}

/// Setting
static bool Debugging, Informing, ShowingName;
private static File CurrentFile;

private static int main(string[] args)
{
    size_t l = args.length;
    
    if (l <= 1)
    {
        print_help;
        return 0;
    }

    for (int i = 0; i < l; ++i)
    {
        switch (args[i])
        {
        case "-d", "--debug", "/d", "/debug":
            Debugging = true;
            writeln("Debugging mode turned on");
            break;
        case "-s", "--showname", "/s", "/showname":
            ShowingName = true;
            break;
        case "-m", "--more", "/m", "/more":
            Informing = true;
            break;
        /*case "-t", "/t":

            break;*/
        case "-h":
            print_help;
            return 0;
        case "--help", "/?":
            print_help_full;
            return 0;
        case "-v", "--version", "/ver", "/version":
            print_version;
            return 0;
        default:
        }
    }

    string filename = args[l - 1]; // Last argument, no exceptions!

    if (exists(filename))
    {
        if (isDir(filename))
            writefln("%s: Directory", filename);
        else
        {
            if (Debugging)
                writefln("L%04d: Opening file..", __LINE__);
            CurrentFile = File(filename, "rb");
            
            if (Debugging)
                writefln("L%04d: Scaning file..", __LINE__);
            scan_file(CurrentFile);
            
            if (Debugging)
                writefln("L%04d: Closing file..", __LINE__);
            CurrentFile.close();
        }
    }
    else
    {
        report("File does not exist");
        return 1;
    }

    return 0;
}

static void print_help()
{
    writefln(" Usage: %s [<Options>] <File>", PROJECT_NAME);
    writefln("        %s [-h|--help|-v|--version]", PROJECT_NAME);
}

static void print_help_full()
{
    writefln(" Usage: %s [<Options>] <File>", PROJECT_NAME);
    writeln("Determine the nature of the file with the file signature.\n");
    writeln("  Switch          Description (Default value)");
    writeln("  -m, --more      Print all information if available. (False)");
    writeln("  -s, --showname  Show filename alongside result. (False)");
    writeln("  -d, --debug     Print debugging information. (False)");
    writeln("\n  -h, --help, /?  Print help and exit");
    writeln("  -v, --version   Print version and exit");
}

static void print_version()
{
    writefln("%s - v%s", PROJECT_NAME, PROJECT_VERSION);
    writeln("Copyright (c) 2016-2017 dd86k");
    writeln("License: MIT");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    writefln("Compiled %s on %s with %s v%s",
        __FILE__, __TIMESTAMP__, __VENDOR__, __VERSION__);
}

static void scan_file(File file)
{
    if (file.size == 0)
    {
        report("Empty file");
        return;
    }

    char[4] sig; // UTF-8, ASCII compatible.
    if (Debugging)
        writefln("L%04d: Reading file..", __LINE__);
    file.rawRead(sig);

    if (Debugging)
    {
        writef("L%04d: Magic - ", __LINE__);
        foreach (b; sig) writef("%X ", b);
        writeln();
    }

    switch (sig)
    {
    /*case "PANG": // PANGOLIN SECURE -- Pangolin LD2000
        write("LD2000 Frame file (LDS)");
        break;*/

    /*case [0xBE, 0xBA, 0xFE, 0xCA]: // Conflicts with Mach-O
        report("Palm Desktop Calendar Archive (DBA)");
        break;*/

    case [0x00, 0x01, 0x42, 0x44]:
        report("Palm Desktop To Do Archive (DBA)");
        return;

    case [0x00, 0x01, 0x44, 0x54]:
        report("Palm Desktop Calendar Archive (TDA)");
        return;

    case [0x00, 0x01, 0x00, 0x00]: {
        char[12] b;
        file.rawRead(b);
        switch (b[0..3])
        {
            case "MSIS":
                report("Microsoft Money file");
                return;
            case "Stan":
                switch (b[8..11])
                {
                    case " ACE":
                        report("Microsoft Access 2007 file");
                        return;
                    case " Jet":
                        report("Microsoft Access file");
                        return;
                    default:
                        report_unknown();
                        return;
                }
            default:
                {
                    if (b[0] == 0)
                        report("TrueType font file");
                    else
                        report("Palm Desktop Data File (Access format)");
                }
                return;
        }
        }

    case "NESM": {
        char[1] b;
        file.rawRead(b);

        switch (b)
        {
        case x"1A": {
            struct nesm_hdr {
                char[5] magic;
                ubyte version_, total_song, start_song;
                ushort load_add, init_add, play_add;
                char[32] song_name, song_artist, song_copyright;
                ushort ntsc_speed; // 1/1000000th sec ticks
                ubyte[8] init_values; // Bankswitch Init Values
                ushort pal_speed;
                ubyte flag; // NTSC/PAL
                ubyte chip;
            }

            nesm_hdr h;
            {
                ubyte[nesm_hdr.sizeof] buf;
                file.rewind();
                file.rawRead(buf);
                memcpy(&h, &buf, nesm_hdr.sizeof);
            }
            
            if (h.flag & 0b10)
                report("Dual NTSC/PAL", false);
            else if (h.flag & 1)
                report("NSTC", false);
            else
                report("PAL", false);

            writef(" Nintendo Sound Format file with %d songs, using ", h.total_song);

            if (h.chip & 1)
                write("VRCVI");
            else if (h.chip & 0b10)
                write("VRCVII");
            else if (h.chip & 0b100)
                write("FDS");
            else if (h.chip & 0b1000)
                write("MMC5");
            else if (h.chip & 0b1_0000)
                write("Namco 106");
            else if (h.chip & 0b10_0000)
                write("Sunsoft FME-07");
            else
                write("no");

            size_t s0, s1, s2;
            char*
                p0 = h.song_name.ptr,
                p1 = h.song_artist.ptr,
                p2 = h.song_copyright.ptr;

            while (*p0++ != '\0') ++s0;
            while (*p1++ != '\0') ++s1;
            while (*p2++ != '\0') ++s2;

            writefln(" extra chip\n%s - %s\nCopyrights:%s",
                h.song_artist[0..s1], h.song_name[0..s0], h.song_copyright[0..s2]);
            }
            return;
        default:
            report_unknown();
            return;
        }
    }

    case "KSPC": {
        char[1] b;
        file.rawRead(b);
        switch (b)
        {
            case x"1A": {
                struct spc2_hdr {
                    char[5] magic;
                    ubyte majorver, minorver;
                    ushort number;
                }

                spc2_hdr h;
                {
                    char[spc2_hdr.sizeof] buf;
                    file.rewind();
                    file.rawRead(buf);
                    memcpy(&h, &buf, spc2_hdr.sizeof);
                }

                report(format("SNES SPC2 v%d.%d file with %d of SPC entries",
                    h.majorver, h.minorver, h.number));
            }
                return;
            default:
                report_unknown();
                return;
        }
    }

    case [0x00, 0x00, 0x01, 0x00]:
        report("Icon, ICO format");
        return;

    case [0, 1, 0, 8]:
        report("Ventura Publisher/GEM VDI Image Format Bitmap file");
        return;

    case "BACK":
        file.rawRead(sig);
        switch (sig)
        {
        case "MIKE":
            file.rawRead(sig);
            switch (sig)
            {
            case "DISK":
                report("AmiBack backup");
                return;
            default:
                report_unknown();
                return;
            }

        default:
            report_unknown();
            return;
        }

    case "GIF8":
        {
            char[2] b;
            file.rawRead(b);
            switch (b)
            {
            case "7a":
                report("GIF87a");
                return;
            case "9a":
                report("GIF89a");
                return;
            default:
                report_unknown();
                return;
            }
        }

    case [0, 0, 1, 0xBA]:
        report("DVD Video Movie File or DVD MPEG2");
        return;

    case "MM\0*":
        report("Tagged Image File Format image (TIFF)");
        return;

    case "II*\0":
        {
            char[6] b;
            file.rawRead(b);
            switch (b)
            {
            case [0x10, 0, 0, 0, 'C', 'R']:
                report("Canon RAW Format Version 2 image (TIFF)");
                return;

            default:
                report("Tagged Image File Format image (TIFF)");
                return;
            }
        }

    case [0, 0, 0, 0xc]:
        report("Various JPEG-2000 image file formats");
        return;

    case [0x80, 0x2A, 0x5F, 0xD7]:
        report("Kodak Cineon image");
        return;

    case ['R', 'N', 'C', 0x01]:
    case ['R', 'N', 'C', 0x02]:
        report("Compressed file (Rob Northen Compression v" ~
            (sig[3] == 1 ? '1' : '2') ~ ")");
        return;

    case "SDPX":
    case "XPDS":
        report("SMPTE DPX image");
        return;

    case [0x76, 0x2F, 0x31, 0x01]:
        report("OpenEXR image");
        return;

    case "BPGû":
        report("Better Portable Graphics image (BPG)");
        return;

    case [0xFF, 0xD8, 0xFF, 0xDB]:
    case [0xFF, 0xD8, 0xFF, 0xE0]:
    case [0xFF, 0xD8, 0xFF, 0xE1]:
        report("Joint Photographic Experts Group image (JPEG)");
        return;

    case ['g', 0xA3, 0xA1, 0xCE]:
        report("IMG archive");
        return;

    case "GBLE", "GBLF", "GBLG", "GBLI", "GBLS", "GBLJ":
        report("%s: GTA Text (GTA2+) file in ", false);
        final switch (sig[3])
        {
        case 'E': write("English");  break;
        case 'F': write("French");   break;
        case 'G': write("German");   break;
        case 'I': write("Italian");  break;
        case 'S': write("Spanish");  break;
        case 'J': write("Japanese"); break;
        }
        write(" language");
        return;

    case "2TXG": {
        ubyte[4] b;
        file.rawRead(b);
        report(format("GTA Text 2 file with %d entries",
            b[0] | b[1] << 8 | b[2] << 16 | b[3] << 24 // Byte swapped
            ));
    }
        return;

    case "RPF0", "RPF2", "RPF3", "RPF4", "RPF6", "RPF7": {
        writef("%s: RPF", file.name);
        int[4] buf; // Table of Contents Size, Number of Entries, ?, Encryted
        file.rawRead(buf);
        if (buf[3])
            write(" encrypted");
        write(" archive v" ~ sig[3] ~ " (");
        final switch (sig[3])
        {
            case '0': write("Table Tennis"); break;
            case '2': write("GTA IV"); break;
            case '3': write("GTA IV:A&MC:LA"); break;
            case '4': write("Max Payne 3"); break;
            case '6': write("Red Dead Redemption"); break;
            case '7': write("GTA V"); break;
        }
        writefln(") with %d entries", buf[1]);
    }
        return;

    case [0, 0, 0, 0x14]:
    case [0, 0, 0, 0x18]:
    case [0, 0, 0, 0x1C]:
    case [0, 0, 0, 0x20]: {
        char[8] b;
        file.rawRead(b);
        switch (b[0..3])
        {
        case "ftyp":
            switch (b[4..7])
            {
            case "isom":
                report("ISO Base Media file (MPEG-4) v1");
                return;
            case "qt  ":
                report("QuickTime movie file");
                return;
            case "3gp5":
                report("MPEG-4 video files (MP4)");
                return;
            case "mp42":
                report("MPEG-4 video/QuickTime file (MP4)");
                return;
            case "MSNV":
                report("MPEG-4 video file (MP4)");
                return;
            case "M4A ":
                report("Apple Lossless Audio Codec file (M4A)");
                return;
            default:
                switch (b[4..6])
                {
                case "3gp":
                    report("3rd Generation Partnership Project multimedia file (3GP)");
                    return;
                default:
                    report_unknown();
                    return;
                }
            }
        default:
            report_unknown();
            return;
        }
    }

    case "FORM": {
        char[4] b;
        file.seek(8);
        file.rawRead(b);
        switch (b)
        {
        case "ILBM":
            report("IFF Interleaved Bitmap Image");
            return;
        case "8SVX":
            report("IFF 8-Bit Sampled Voice");
            return;
        case "ACBM":
            report("Amiga Contiguous Bitmap");
            return;
        case "ANBM":
            report("IFF Animated Bitmap");
            return;
        case "ANIM":
            report("IFF CEL Animation");
            return;
        case "FAXX":
            report("IFF Facsimile Image");
            return;
        case "FTXT":
            report("IFF Formatted Text");
            return;
        case "SMUS":
            report("IFF Simple Musical Score");
            return;
        case "CMUS":
            report("IFF Musical Score");
            return;
        case "YUVN":
            report("IFF YUV Image");
            return;
        case "FANT":
            report("Amiga Fantavision Movie");
            return;
        case "AIFF":
            report("Audio Interchange File Format");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case [0, 0, 1, 0xB7]:
        report("MPEG video file");
        return;

    case "INDX":
        report("AmiBack backup index file");
        return;

    case "LZIP":
        report("lzip compressed file");
        return;

    case "PK\x03\x04":
        report("EPUB document");
        return;

    //case ['P', 'K', 0x03, 0x04]: Conflicts with EPUB
    case ['P', 'K', 0x05, 0x06]:
    case ['P', 'K', 0x07, 0x08]:
        report("ZIP compressed file (or JAR, ODF, OOXML)");
        return;

    case "Rar!":
        file.rawRead(sig);
        switch (sig)
        {
        case [0x1A, 0x07, 0x01, 0x00]:
            report("RAR archive v5.0+");
            return;
        default:
            report("RAR archive v1.5+");
            return;
        }

    case "\x7FELF":
        scan_elf(file);
        return;

    case [0xFA, 0x70, 0x0E, 0x01]: // FatELF - 0x1F0E70FA
        scan_fatelf(file);
        return;

    case [0x89, 'P', 'N', 'G']:
        file.rawRead(sig);
        switch (sig)
        {
        case [0x0D, 0x0A, 0x1A, 0x0A]:
            report("Portable Network Graphics image (PNG)");
            return;
        default:
            report_unknown();
            return;
        }
    
    case [0xFE, 0xED, 0xFA, 0xCE]:
    case [0xFE, 0xED, 0xFA, 0xCF]:
    case [0xCE, 0xFA, 0xED, 0xFE]:
    case [0xCF, 0xFA, 0xED, 0xFE]:
    case [0xCA, 0xFE, 0xBA, 0xBE]:
    case [0xBE, 0xBA, 0xFE, 0xCA]:
        scan_mach(file);
        return;

    case [0xFF, 0xFE, 0x00, 0x00]:
        report("UTF-32 text file (byte-order mark)");
        return;

    case "%!PS":
        report("PostScript document");
        return;

    case "%PDF":
        file.rawRead(sig);
        report(format("PDF%s document", sig));
        return;

    case [0x30, 0x26, 0xB2, 0x75]: {
        char[12] b;
        file.rawRead(b);
        switch (b)
        {
        case [0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9, 0, 0xAA, 0, 0x62, 0xCE, 0x6C]:
            report("Advanced Systems Format file (ASF, WMA, WMV)");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case "$SDI":
        file.rawRead(sig);
        switch (sig)
        {
        case [0x30, 0x30, 0x30, 0x31]:
            report("System Deployment Image (Microsoft disk image)");
            return;
        default:
            report_unknown();
            return;
        }

    case "OggS":
        report("Ogg audio file");
        return;

    case "8BPS":
        report("Photoshop native document file");
        return;

    case "RIFF":
        file.seek(8);
        file.rawRead(sig);
        switch (sig)
        {
        case "WAVE":
            report("Waveform Audio File (wav)");
            return;
        case "AVI ":
            report("Audio Video Interface video (avi)");
            return;
        default:
            report_unknown();
            return;
        }

    case "SIMP":
        file.rawRead(sig);
        switch (sig)
        {
        case "LE  ":
            report("Flexible Image Transport System (FITS)");
            return;
        default:
            report_unknown();
            return;
        }

    case "fLaC":
        report("Free Lossless Audio Codec audio file (FLAC)");
        return;

    case "MThd": {
        struct midi_hdr {
            char[4] magic;
            uint length;
            ushort format, number, division;
        }

        midi_hdr h;
        {
            ubyte[midi_hdr.sizeof] buf;
            file.rewind();
            file.rawRead(buf);
            memcpy(&h, &buf, midi_hdr.sizeof);
        }

        switch (h.format) // Big Endian
        {
            case 0: report("Single track MIDI", false); break;
            case 0x100: report("Multiple track MIDI", false); break; // 1
            case 0x200: report("multiple song format", false); break;  // 2
            default: report("MIDI with unknown format"); return;
        }

        // Big Endian
        h.number = cast(ushort)((h.number >> 8) | (h.number << 8));
        h.division = cast(ushort)((h.division >> 8) | (h.division << 8));
        writef(" using %d tracks at ", h.number);

        if (h.division & 0x8000) // Negative, SMPTE units
            writef("%d ticks per frame (SMPTE: %d)",
                h.division & 0xFF, h.division >> 8 & 0xFF);
        else // Ticks per beat
            writef("%d ticks per quarter-note", h.division);
    }
        return;

    case [0xD0, 0xCF, 0x11, 0xE0]:
        file.rawRead(sig);
        switch (sig)
        {
        case [0xA1, 0xB1, 0x1A, 0xE1]:
            report("Compound File Binary Format document (doc, xls, ppt)");
            return;
        default:
            report_unknown();
            return;
        }

    case ['d', 'e', 'x', 0x0A]:
        file.rawRead(sig);
        switch (sig)
        {
        case "035\0":
            report("Dalvik Executable");
            return;
        default:
            report_unknown();
            return;
        }

    case "Cr24":
        report("Google Chrome extension or packaged app (crx)");
        return;

    case "AGD3":
        report("FreeHand 8 document (fh8)");
        return;

    case [0x05, 0x07, 0x00, 0x00]: {
        char[6] b;
        file.rawRead(b);
        switch (b)
        {
        case [0x4F, 0x42, 0x4F, 0x05, 0x07, 0x00]:
            report("AppleWorks 5 document (cwk)");
            return;
        case [0x4F, 0x42, 0x4F, 0x06, 0x07, 0xE1]:
            report("AppleWorks 6 document (cwk)");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case ['E', 'R', 0x02, 0x00]:
        report("Roxio Toast disc image or DMG file (toast or dmg)");
        return;

    case ['x', 0x01, 's', 0x0D]:
        report("Apple Disk Image file (dmg)");
        return;

    case "xar!":
        report("eXtensible ARchive format (xar)");
        return;

    case "PMOC":
        file.rawRead(sig);
        switch (sig)
        {
        case "CMOC":
            report("USMT, Windows Files And Settings Transfer Repository (dat)");
            return;
        default:
            report_unknown();
            return;
        }

    case "TOX3":
        report("Open source portable voxel file");
        return;

    case "MLVI":
        report("Magic Lantern Video file");
        return;

    case "DCM\0":
        file.rawRead(sig);
        switch (sig)
        {
        case "PA30":
            report("Windows Update Binary Delta Compression file");
            return;
        default:
            report_unknown();
            return;
        }

    case [0x37, 0x7A, 0xBC, 0xAF]: {
        char[2] b;
        file.rawRead(b);
        switch (b)
        {
        case [0x27, 0x1C]:
            report("7-Zip compressed file (7z)");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case [0x04, 0x22, 0x4D, 0x18]:
        report("LZ4 Streaming Format (lz4)");
        return;

    case "MSCF":
        report("Microsoft Cabinet File (cab)");
        return;

    case "FLIF":
        report("Free Lossless Image Format image file (flif)");
        return;

    case [0x1A, 0x45, 0xDF, 0xA3]:
        report("Matroska media container (mkv, webm)");
        return;

    case "MIL ":
        report(`"SEAN : Session Analysis" Training file`);
        return;

    case "AT&T":
        file.rawRead(sig);
        switch (sig)
        {
        case "FORM":
            file.seek(4, SEEK_CUR);
            file.rawRead(sig);
            switch (sig)
            {
            case "DJVU":
                report("DjVu document, single page");
                return;
            case "DJVM":
                report("DjVu document, multiple pages");
                return;
            default:
                report_unknown();
                return;
            }
        default:
            report_unknown();
            return;
        }

    case "wOFF":
        report("WOFF File Format 1.0 font (woff)");
        return;

    case "wOF2":
        report("WOFF File Format 2.0 font (woff)");
        return;

    case "<?xm": {
        char[2] b;
        file.rawRead(b);
        switch (b)
        {
        case "l>":
            report("ASCII XML (xml)");
            return;
        default:
            report_unknown();
            return;
        }
    } // too lazy for utf-16/32

    case "PWAD":
    case "IWAD": {
        int[2] b; // Doom reads as int
        file.rawRead(b);
        report(format("%s holding %d entries at %Xh", sig, b[0], b[1]));
    }
        return;

    case "\0asm":
        report("WebAssembly file (wasm)");
        return;

    case "TRUE": {
        char[12] b;
        file.rawRead(b);
        switch (b)
        {
        case "VISION-XFILE":
            report("Truevision Targa Graphic image file");
            return;
        default:
            report_unknown();
            return;
        }
    }
    
    // http://www.cabextract.org.uk/libmspack/doc/szdd_kwaj_format.html
    case "KWAJ": {
        struct kwaj_hdr {
            char[8] sig;
            ushort method; // compressed method
            ushort offset;
            ushort header; // header flag
        }

        kwaj_hdr h;
        {
            enum size_t s = kwaj_hdr.sizeof;
            ubyte[s] b;
            file.rewind;
            file.rawRead(b);
            memcpy(&h, &b, s);
        }

        report("MS-DOS ", false);

        switch (h.method)
        {
            case 0: write("Non-compressed"); break;
            case 1: write("FFh-XORed data"); break;
            case 2: write("Regular SZDD Compressed"); break;
            case 3: write("LZ + Huffman \"Jeff Johnson\" Compressed"); break;
            case 4: write("MS-ZIP Compressed"); break;
            default: write("Unknown compression");
        }

        write(" file (KWAJ)");

        if (h.offset)
            writef(" (offset:%Xh)", h.offset);

        enum { // Header flags
            ULENGHT = 1, // 4 bytes, uncompressed data length
            UNKNOWN = 2, // 2 bytes
            DLENGHT = 4, // 2 bytes, data length?
            NAME = 8,    // ASCIZ, filename
            EXT = 0x10,  // ASCIZ, extension
        }

        int ext = h.header & EXT, name = h.header & NAME;

        if (ext || name)
        {
            int offset;
            if (h.header & ULENGHT) offset += 4;
            if (h.header & UNKNOWN) offset += 2;
            if (h.header & DLENGHT) offset += 2;

            if (offset) file.seek(offset, SEEK_CUR);

            write(" Out:");

            if (name)
                write(file.readln('\0'));
            write('.');
            if (ext)
                write(file.readln('\0'));
        }

        writeln();
    }
        break;

    case "SZDD": {
        struct szdd_hdr {
            char[8] sig;
            ubyte compression; // compressed mode, only 'A' is valid
            ubyte character; // filename end character (0=unknown)
            uint length; // unpacked
        }

        szdd_hdr h;
        {
            enum size_t s = szdd_hdr.sizeof;
            ubyte[s] b;
            file.rewind;
            file.rawRead(b);
            memcpy(&h, &b, s);
        }

        report("MS-DOS ", false);

        if (h.compression == 'A')
            write("SZDD");
        else
            write("Non-valid SZDD");

        writeln(" Compressed file (SZDD)");
    }
        break;

    case [0, 0, 2, 0]:
        report("Lotus 1-2-3 spreadsheet (v1) file");
        return;

    case [0, 0, 0x1A, 0]: {
        char[3] b;
        file.rawRead(b);
        switch (b)
        {
        case [0, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v3) file");
            return;
        case [2, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v4, v5) file");
            return;
        case [5, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v9) file");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case [0, 0, 3, 0xF3]:
        report("Amiga Hunk executable file");
        return;    

    case "\0\0II":
    case "\0\0MM":
        report("Quark Express document");
        return;

    case [0, 0, 0xFE, 0xFF]:
        report("UTF-32BE BOM");
        return;

    case "HDR0": {
        struct trx_hdr {
            uint magic;
            uint length;
            uint crc;
            ushort flags;
            ushort version_;
        }

        trx_hdr h;
        {
            ubyte[trx_hdr.sizeof] buf;
            file.rawRead(buf);
            memcpy(&h, &buf, trx_hdr.sizeof);
        }

        if (h.version_ == 1 || h.version_ == 2)
            report(format(
                "TRX v%d firmware (Length: %d, CRC32: %Xh)", h.version_, h.length, h.crc
            ));
        else
            report_unknown();
    }
        return;

    default:
        switch (sig[0..2])
        {
        case [0x1F, 0x9D]:
            report("Lempel-Ziv-Welch compressed file (RAR/ZIP)");
            return;

        case [0x1F, 0xA0]:
            report("LZH compressed file (RAR/ZIP)");
            return;

        case "MZ":
            scan_mz(file);
            return;

        case [0xFF, 0xFE]:
            report("UTF-16 text file (Byte-Order mark)");
            return;

        case [0xFF, 0xFB]:
            report("MPEG-2 Audio Layer III audio file (MP3)");
            return;

        case "BM":
            report("Bitmap iamge file (BMP)");
            return;

        case [0x1F, 0x8B]:
            report("GZIP compressed file ([tar.]gz)");
            return;

        case [0x30, 0x82]:
            report("DER encoded X.509 certificate (der)");
            return;

        default:
            switch (sig[0..3])
            {
            case "BZh":
                report("Bzip2 compressed file (BZh)");
                return;

            case [0xEF, 0xBB, 0xBF]:
                report("UTF-8 text file with BOM");
                return;

            case "ID3":
                report("MPEG-2 Audio Layer III audio file with ID3v2 container (MP3)");
                return;

            case "KDM":
                report("VMware Disk K virtual disk file (VMDK)");
                return;

            case "NES":
                report("Nintendo Entertainment System ROM file (nes)");
                return;

            case [0xCF, 0x84, 0x01]:
                report("Lepton compressed JPEG image (lep)");
                return;

            case [0, 1, 1]:
                report("OpenFlight 3D file");
                return;

            default:
                scan_unknown(file);
                return;
            } // 3 Byte signatures
        } // 2 Byte signatures
    } // sig (4 Byte)
}

static void report_unknown()
{
    report("Unknown file type");
}

static void report(string type, bool nl = true)
{
    if (ShowingName)
        writef("%s: %s", CurrentFile.name, type);
    else
        write(type);

    if (nl)
        writeln();
}