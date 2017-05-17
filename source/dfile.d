/*
 * General.d : Where the adventure begins.
 */

module dfile;

import std.stdio;
import s_elf : scan_elf;
import s_fatelf : scan_fatelf;
import s_mz : scan_mz;
import s_pe : scan_pe;
import s_ne : scan_ne;
import s_le : scan_le;
import s_mach : scan_mach;
import s_images, Etc, utils;

bool More, /// -m : More flag
     ShowingName, /// -s : Show name flag
     Base10; /// -b : Base 10 flag
/// Current file handle.
File CurrentFile;

/**
 * Prints debugging message with a FILE<at>LINE: MSG formatting.
 * Params:
 *   msg = Message
 *   line = Source line (automatic)
 *   file = Source file (automatic)
 */
debug void dbg(string msg, int line = __LINE__, string file = __FILE__) {
    dbgl(msg, line, file);
    writeln;
}

/**
 * Same as dbg but without a newline.
 * Params:
 *   msg = Message
 *   line = Source line (automatic)
 *   file = Source file (automatic)
 * See_Also: dbg
 */
debug void dbgl(string msg, int line = __LINE__, string file = __FILE__) {
    import std.path : baseName;
    writef("%s@L%d: %s", baseName(file), line, msg);
}

/**
 * Scanner entry point.
 * Params: file = File handle
 */
void scan(File file)
{
    if (file.size == 0)
    {
        report("Empty file");
        return;
    }

    char[4] sig; // UTF-8, ASCII compatible.
    file.rawRead(sig);
    version (X86) {
        uint s = void;
        asm pure @nogc {
            lea ESI, sig;
            mov EBX, [ESI];
            mov s, EBX;
        }
    } else version (X86_64) {
        uint s = void;
        asm pure @nogc {
            lea RSI, sig;
            mov EBX, [RSI];
            mov s, EBX;
        }
    } else uint s = *cast(uint*)&sig[0];
    debug writefln("s::%08X", s);

    debug
    {
        dbgl("Magic: ");
        foreach (b; sig) writef("%02X ", b);
        writeln();
    }

    //TODO: Switch back to sig
    switch (s)
    {
    /*case "PANG": // PANGOLIN SECURE -- Pangolin LD2000
        write("LD2000 Frame file (LDS)");
        break;*/

    /*case [0xBE, 0xBA, 0xFE, 0xCA]: // Conflicts with Mach-O
        report("Palm Desktop Calendar Archive (DBA)");
        break;*/

    case 0x44420100:
        report("Palm Desktop To Do Archive (DBA)");
        return;

    case 0x54440100:
        report("Palm Desktop Calendar Archive (TDA)");
        return;

    case 0x00000100: {
        char[12] b;
        file.rawRead(b);
        switch (b[0..4])
        {
            case "MSIS":
                report("Microsoft Money file");
                return;
            case "Stan":
                switch (b[8..12])
                {
                    case " ACE":
                        report("Microsoft Access 2007 Database");
                        return;
                    case " Jet":
                        report("Microsoft Access Database");
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

    case 0x4D53454E: { // "NESM"
        char[1] b;
        file.rawRead(b);

        switch (b)
        {
        case x"1A": {
            struct nesm_hdr { align(1):
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
            scpy(file, &h, h.sizeof, true);
            
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

            writefln(" extra chip\n%s - %s\nCopyrights:%s",
                asciz(h.song_artist),
                asciz(h.song_name),
                asciz(h.song_copyright));
            }
            return;
        default:
            report_unknown();
            return;
        }
    }

    case 0x4350534B: { // "KSPC"
        char[1] b;
        file.rawRead(b);
        switch (b)
        {
            case x"1A": {
                struct spc2_hdr { align(1):
                    char[5] magic;
                    ubyte majorver, minorver;
                    ushort number;
                }

                spc2_hdr h;
                scpy(file, &h, h.sizeof, true);

                report("SNES SPC2 v", false);
                writeln(h.majorver, ".", h.minorver, " file with",
                    h.number, " of SPC entries");
            }
                return;
            default:
                report_unknown();
                return;
        }
    }

    case 0x00010000:
        report("Icon, ICO format");
        return;

    case 0x08000100:
        report("Ventura Publisher/GEM VDI Image Format Bitmap file");
        return;

    case 0x4B434142: // "BACK"
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

    case 0xBA010000:
        report("DVD Video Movie File or DVD MPEG2");
        return;

    case 0x2A004D4D: // "MM\0*"
        report("Tagged Image File Format image (TIFF)");
        return;

    case 0x002A4949: { // "II*\0"
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

    case 0x0C000000:
        report("Various JPEG-2000 image file formats");
        return;

    case 0xD75F2A80:
        report("Kodak Cineon image");
        return;

    case 0x01434E52, 0x02434E52: // RNC\x01 or \x02
        report("Rob Northen Compressed archive v" ~
            (sig[3] == 1 ? '1' : '2') ~ ")");
        return;

    case 0x58504453, 0x53445058: // "SDPX", "XPDS"
        report("SMPTE DPX image");
        return;

    case 0x01312F76:
        report("OpenEXR image");
        return;

    case 0xFB475042: // BPGû
        report("Better Portable Graphics image (BPG)");
        return;

    case 0xDBFFD8FF, 0xE0FFD8FF, 0xE1FFD8FF:
        report("Joint Photographic Experts Group image (JPEG)");
        return;

    case 0xCEA1A367:
        report("IMG archive");
        return;

    //case "GBLE", "GBLF", "GBLG", "GBLI", "GBLS", "GBLJ":
    case 0x454C4247, 0x464C4247, 0x474C4247,
         0x494C4247, 0x534C4247, 0x4A4C4247:
        report("%s: GTA Text (GTA2+) file in ", false);
        final switch (sig[3])
        {
        case 'E': writeln("English");  break;
        case 'F': writeln("French");   break;
        case 'G': writeln("German");   break;
        case 'I': writeln("Italian");  break;
        case 'S': writeln("Spanish");  break;
        case 'J': writeln("Japanese"); break;
        }
        return;

    case 0x47585432: { // "2TXG"
        uint[1] b;
        file.rawRead(b);
        report("GTA Text 2 file with", false);
        writeln(bswap(b[0]), "entries");  // Byte swapped
    }
        return;

    //case "RPF0", "RPF2", "RPF3", "RPF4", "RPF6", "RPF7": {
    case 0x30465052, 0x32465052, 0x33465052,
         0x34465052, 0x36465052, 0x37465052: {
        struct rpf_hdr { align(1):
            //int magic;
            int tablesize;
            int numentries;
            int unknown0;
            int encrypted;
        }
        rpf_hdr h;
        scpy(file, &h , h.sizeof);
        report("RPF", false);
        if (h.encrypted)
            write(" encrypted");
        write(" archive v", sig[3], " (");
        final switch (sig[3])
        {
            case '0': write("Table Tennis"); break;
            case '2': write("GTA IV"); break;
            case '3': write("GTA IV:A&MC:LA"); break;
            case '4': write("Max Payne 3"); break;
            case '6': write("Red Dead Redemption"); break;
            case '7': write("GTA V"); break;
        }
        writefln(") with ", h.numentries, " entries");
    }
        return;

    case 0x14000000, 0x18000000, 0x1C000000, 0x20000000: {
        char[8] b;
        file.rawRead(b);
        switch (b[0..4])
        {
        case "ftyp":
            switch (b[4..8])
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
                switch (b[4..7])
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

    case 0x4D524F46: { // "FORM"
        char[4] b;
        file.seek(8);
        file.rawRead(b);
        switch (b) {
        case "ILBM": report("IFF Interleaved Bitmap Image"); return;
        case "8SVX": report("IFF 8-Bit Sampled Voice"); return;
        case "ACBM": report("Amiga Contiguous Bitmap"); return;
        case "ANBM": report("IFF Animated Bitmap"); return;
        case "ANIM": report("IFF CEL Animation"); return;
        case "FAXX": report("IFF Facsimile Image"); return;
        case "FTXT": report("IFF Formatted Text"); return;
        case "SMUS": report("IFF Simple Musical Score"); return;
        case "CMUS": report("IFF Musical Score"); return;
        case "YUVN": report("IFF YUV Image"); return;
        case "FANT": report("Amiga Fantavision Movie"); return;
        case "AIFF": report("Audio Interchange File Format"); return;
        default: report_unknown(); return;
        }
    }

    case 0xB7010000:
        report("MPEG video file");
        return;

    case 0x58444E49: // INDX
        report("AmiBack backup index file");
        return;

    case 0x50495A4C: // "LZIP"
        report("LZIP Archive");
        return;

    //case "PK\x03\x04", "PK\x05\x06", "PK\x07\x08": {
    case 0x04034B42, 0x06054B42, 0x08074B42: {
        struct pkzip_hdr {  align(1): // PKWare ZIP
            //uint magic;
            //ushort magic;
            ushort version_;
            ushort flag;
            ushort compression;
            ushort time; // MS-DOS, 5-bit hours, 6-bit minutes, 5-bit seconds
            ushort date; // MS-DOS, 1980-(7-bit) year, 4-bit month, 5-bit day
            uint crc32;
            uint csize; // compressed size
            uint usize; // uncompressed size
            ushort fnlength; // filename length
            ushort eflength; // extra field length
        }

        pkzip_hdr h;
        scpy(file, &h, h.sizeof);

        if (More)
        {
            //writeln("magic      : ", h.magic);
            writeln("Version    : ", h.version_);
            writeln("Flag       : ", h.flag);
            writeln("Compression: ", h.compression);
            writeln("Time       : ", h.time);
            writeln("Date       : ", h.date);
            writeln("CRC32      : ", h.crc32);
            writeln("Size (Uncompressed): ", h.usize);
            writeln("Size (Compressed)  : ", h.csize);
            writeln("Filename Size      : ", h.fnlength);
            writeln("Extra field Size   : ", h.eflength);
        }

        debug writefln("FNLENGTH: %X", h.fnlength);

        report("ZIP ", false); // JAR, ODF, OOXML, EPUB

        switch (h.compression)
        {
            case 0: write("Uncompressed"); break;
            case 1: write("Shrunk"); break;
            case 2: .. // 2 to 5
            case 5: write("Reduced by ", h.compression - 1); break;
            case 6: write("Imploded"); break;
            case 8: write("Deflated"); break;
            case 9: write("Enhanced Deflated"); break;
            case 10: write("DCL Imploded (PKWare)"); break;
            case 12: write("BZIP2"); break;
            case 14: write("LZMA"); break;
            case 18: write("IBM TERSE"); break;
            case 19: write("IBM LZ77 z"); break;
            case 98: write("PPMd Version I, Rev 1"); break;
            default: write("Unknown"); break;
        }

        write(" Archive (v", h.version_ / 10, ".", h.version_ % 10, "), ",
            formatsize(h.csize), "/", formatsize(h.usize));

        if (h.fnlength)
        {
            file.seek(-2, SEEK_CUR);
            char[] filename = new char[h.fnlength];
            file.rawRead(filename);
            write(` "`, filename, `"`);
        }

        enum {
            ENCRYPTED = 1, // 1
            ENHANCED_DEFLATION = 16, // 4
            COMPRESSED_PATCH = 32, // 5, data
            STRONG_ENCRYPTION = 64, // 6
        }

        if (h.flag & ENCRYPTED)
            write(", Encrypted");

        if (h.flag & STRONG_ENCRYPTION)
            write(", Strongly encrypted");

        writeln();
    }
        return;

    case 0x21726152: { // "Rar!"
        file.rawRead(sig);
        switch (sig)
        {
        case [0x1A, 0x07, 0x01, 0x00]:
            //TODO: http://www.rarlab.com/technote.htm
            report("RAR archive v5.0+");
            return;
        default: // 0,1,2
            if (sig[0..3] == x"1A 07 00")
                report("RAR archive v1.5+");
            else
                report_unknown();
            return;
        }
    }

    case 0x464C457F: // "\x7FELF"
        scan_elf(file);
        return;

    case 0x010E70FA: // FatELF - 0x1F0E70FA
        scan_fatelf(file);
        return;

    case 0x474E5089: // "\x89PNG"
        file.rawRead(sig);
        switch (sig)
        {
        case [0x0D, 0x0A, 0x1A, 0x0A]:
            scan_png(file);
            return;
        default:
            report_unknown();
            return;
        }
    
    /*case [0xFE, 0xED, 0xFA, 0xCE]:
    case [0xFE, 0xED, 0xFA, 0xCF]:
    case [0xCE, 0xFA, 0xED, 0xFE]:
    case [0xCF, 0xFA, 0xED, 0xFE]:
    case [0xCA, 0xFE, 0xBA, 0xBE]:
    case [0xBE, 0xBA, 0xFE, 0xCA]:*/
    case 0xCEFAEDFE, 0xCFFAEDFE, 0xFEEDFACE,
         0xFEEDFACF, 0xBEBAFECA, 0xCAFEBABE:
        scan_mach(file);
        return;

    case 0x53502125: // "%!PS"
        report("PostScript document");
        return;

    case 0x46445025: // "%PDF"
        file.rawRead(sig); // for "-1.0"
        report("PDF", false);
        writeln(sig, " document");
        return;

    case 0x75B22630: {
        char[12] b;
        file.rawRead(b);
        switch (b)
        {
        case x"8E 66 CF 11 A6 D9 0 AA 0 62 CE 6C":
            report("Advanced Systems Format file (ASF, WMA, WMV)");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case 0x49445324: // "$SDI"
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

    case 0x5367674F: { // "OggS"
        struct ogg_hdr { align(1):
            //uint magic;
            ubyte version_;
            ubyte type; // Usually bit 2 set
            ulong granulepos;
            uint serialnum;
            uint pageseqnum;
            uint crc32;
            ubyte pages;
        }
        ogg_hdr h;
        scpy(file, &h, h.sizeof);
        report("Ogg audio file v", false);
        writeln(h.version_, " with ", h.pages, " segments");

        if (More)
        {
            writefln("CRC32: %X", h.crc32);
        }
    }
        return;

    case 0x43614C66: { // "fLaC", big endian
    //https://xiph.org/flac/format.html
    //https://xiph.org/flac/api/format_8h_source.html
        struct flac_hdr { align(1):
            //uint magic;
            uint header; // islast (1 bit) + type (7 bits) + length (24 bits)
            ushort minblocksize;
            ushort maxblocksize;
            /*
             * Min and max frames (24 bits each)
             * Sample rate (20 bits)
             * # of channels (3 bits)
             * bits per sample (5 bits)
             * total samples (36 bits)
             * Total : 112 bits (14 bytes)
             */
            ubyte[14] stupid;
            ubyte[16] md5;
        }
        flac_hdr h;
        scpy(file, &h, h.sizeof);
        report("FLAC audio file", false);
        if ((h.header & 0xFF) == 0) // Big endian
        {
            const int bits = ((h.stupid[8] & 1) << 4 | (h.stupid[9] >>> 4)) + 1;
            const int chan = ((h.stupid[8] >> 1) & 7) + 1;
            const int rate =
                ((h.stupid[6] << 12) | h.stupid[7] << 4 | h.stupid[8] >>> 4);
            writeln(", ", rate, " Hz, ", bits, " bit, ", chan, " channels");
            if (More)
            {
                write("MD5: ");
                print_array(&h.md5[0], h.md5.length);
                writeln();
            }
        }
        else
            writeln();
    }
        return;

    case 0x53504238: { // "8BPS", Native Photoshop file
        struct psd_hdr { align(1):
            //ushort magic;
            ushort version_;
            ubyte[6] reserved;
            ushort channels;
            uint height;
            uint width;
            ushort depth;
            ushort colormode;
        }
    //http://www.adobe.com/devnet-apps/photoshop/fileformatashtml/#50577409_19840
        psd_hdr h;
        //file.seek(2);
        scpy(file, &h, h.sizeof);
        report("Photoshop Document v", false);
        write(bswap(h.version_), ", ",
            bswap(h.width), " x ", bswap(h.height), ", ",
            bswap(h.depth), "-bit ");
        switch (bswap(h.colormode))
        {
            case 0: write("Bitmap"); break;
            case 1: write("Grayscale"); break;
            case 2: write("Indexed"); break;
            case 3: write("RGB"); break;
            case 4: write("CMYK"); break;
            case 7: write("Multichannel"); break;
            case 8: write("Duotone"); break;
            case 9: write("Lab"); break;
            default: write("Unknown type"); break;
        }
        writeln(" image, ", bswap(h.channels), " channel(s)");
    }
        return;

    case 0x46464952: // "RIFF"
        file.seek(8);
        file.rawRead(sig);
        switch (sig)
        {
        case "WAVE": {
            //http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html
            struct fmt_chunk { align(1):
                char[4] id;
                uint cksize;
                ushort format;
                ushort channels;
                uint samplerate; // Blocks per second
                uint datarate;
                ushort blocksize;
                ushort samplebits;
                ushort extensionsize;
                ushort nbvalidbits;
                uint speakmask;
                char[16] guid;
            }
            enum {
                PCM = 1,
                IEEE_FLOAT = 3,
                ALAW = 6,
                MULAW = 7,
                EXTENSIBLE = 0xFFFE
            }
            fmt_chunk h;
            scpy(file, &h, h.sizeof);
            report("WAVE audio file (", false);
            if (h.id != "fmt ")
            {
                writeln();
                return;
            }
            switch (h.format)
            {
                case PCM: write("PCM"); break;
                case IEEE_FLOAT: write("IEEE Float"); break;
                case ALAW:  write("8-bit ITU G.711 A-law"); break;
                case MULAW: write("8-bit ITU G.711 u-law"); break;
                case EXTENSIBLE:
                    write("EXTENDED");
                    if (More)
                    {
                        write(":");
                        print_array(&h.guid[0], h.guid.length);
                    }
                    break;
                default: writeln("Unknown type"); return;
            }
            write(") ", h.samplerate, " Hz, ", h.datarate / 1024 * 8,
                " kbps, ", h.samplebits, "-bit, ");
            switch (h.channels)
            {
                case 1: writeln("Mono"); break;
                case 2: writeln("Stereo"); break;
                default: writeln(h.channels, " channels"); break;
            }
        }
            return;
        case "AVI ":
            report("Audio Video Interface video (avi)");
            return;
        default:
            report_unknown();
            return;
        }

    case 0x504D4953: // "SIMP"
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

    case 0x6468544D: { // "MThd", MIDI, Big Endian
        struct midi_hdr { align(1):
            char[4] magic;
            uint length;
            ushort format, number, division;
        }

        midi_hdr h;
        scpy(file, &h, h.sizeof, true);

        report("MIDI, ", false);

        switch (bswap(h.format))
        {
            case 0: write("Single track"); break;
            case 1: write("Multiple tracks"); break;
            case 2: write("Multiple songs"); break;
            default: write("Unknown format"); return;
        }

        h.number = bswap(h.number);
        h.division = bswap(h.division);
        writef(": %d tracks at ", h.number);
        if (h.division & 0x8000) // Negative, SMPTE units
            writefln("%d ticks/frame (SMPTE: %d)",
                h.division & 0xFF, h.division >> 8 & 0xFF);
        else // Ticks per beat
            writefln("%d ticks/quarter-note", h.division);
    }
        return;

    case 0xE011CFD0:
        file.rawRead(sig);
        switch (sig)
        {
        case [0xA1, 0xB1, 0x1A, 0xE1]:
            report("Compound File Binary Format document (doc, xls, ppt, etc.)");
            return;
        default:
            report_unknown();
            return;
        }

    case 0x0A786564: // "dex\x0A"
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

    case 0x34327243: // "Cr24"
        report("Google Chrome extension or packaged app (crx)");
        return;

    case 0x33444741: // "AGD3"
        report("FreeHand 8 document (fh8)");
        return;

    case 0x00000705: {
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

    case 0x00025245:
        report("Roxio Toast disc image or DMG file (toast or dmg)");
        return;

    case 0x0D730178:
        report("Apple Disk Image file (dmg)");
        return;

    case 0x21726178: // "xar!"
        report("eXtensible ARchive format (xar)");
        return;

    case 0x434F4D50: // "PMOC"
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

    case 0x33584F54: // "TOX3"
        report("Open source portable voxel file");
        return;

    case 0x49564C4D: // "MLVI"
        report("Magic Lantern Video file");
        return;

    case 0x004D4344: // "DCM\0"
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

    case 0xAFBC7A37: {
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

    case 0x184D2204:
        report("LZ4 Streaming Format (lz4)");
        return;

    case 0x4643534D: { // "MSCF"
        struct cfh_hdr { align(1):
            //char[4] magic;
            uint reserved1;
            uint size;
            uint reserved2;
            uint offset;
            uint reserved3;
            ubyte minor;
            ubyte major;
            ushort folders;
            ushort files;
            ushort flags;
            ushort id;
            ushort seq;
        }
        cfh_hdr h;
        scpy(file, &h, h.sizeof);
        report("Microsoft Cabinet archive v", false);
        writeln(h.major, ".", h.minor, ", ", formatsize(h.size), ", ",
            h.files, " files and ", h.folders, " folders");
    }
        return;

    case 0x28635349: { // "ISc("
        struct iscab_hdr { align(1):
            //uint magic;
            uint version_;
            uint volumeinfo;
            uint desc_offset;
            uint desc_size;
        }
        enum : uint {
            LEGACY    = 0x000CC9B8,
            v2_20_905 = 0x1234001C,
            v3_00_065 = 0x12340016,
            v5_00_000 = 0x00010050
        }
        iscab_hdr h;
        scpy(file, &h, h.sizeof);
        report("InstallShield CAB archive", false);
        switch (h.version_)
        {
            case LEGACY:    write(" (Legacy)");  break;
            case v2_20_905: write(" v2.20.905"); break;
            case v3_00_065: write(" v3.00.065"); break;
            case v5_00_000: write(" v5.00.000"); break;
            default: writef(" (Version:0x%08X)", h.version_); break;
        }
        writefln(" at 0x%X", h.desc_offset);
    }
        return;

    case 0xA3DF451A:
        report("Matroska media container (mkv, webm)");
        return;

    case 0x204C494D: // "MIL "
        report(`"SEAN : Session Analysis" Training file`);
        return;

    case 0x54265441: // "AT&T"
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

    case 0x46464F77: // "wOFF"
        report("WOFF File Format 1.0 font (woff)");
        return;

    case 0x32464F77: // "wOF2"
        report("WOFF File Format 2.0 font (woff)");
        return;

    case 0x72613C21: { // "!<ar", Debian Package
        struct deb_hdr { align(1): // Ignore fields in caps
            char[8]  magic; // "!<arch>\n"
            char[16] file_iden; // "debian-binary   "
            char[12] timestamp;
            char[6]  uid, gid;
            char[8]  filemode;
            char[10] filesize;
            char[2]  END;
            char[3]  version_;
            char     ENDV;
            char[16] ctl_file_ident;
            char[12] ctl_timestamp;
            char[6]  ctl_uid, ctl_gid;
            char[8]  ctl_filemode;
            char[10] ctl_filesize;
            char[2]  CTL_END;
        }
        struct deb_data_hdr { align(1):
            char[16] file_ident;
            char[12] timestamp;
            char[6]  uid, gid;
            char[8]  filemode;
            char[10] filesize;
            char[2]  END;
        }
        enum DEBIANBIN = "debian-binary   ";
        deb_hdr h;
        scpy(file, &h, h.sizeof, true);
        if (h.file_iden != DEBIANBIN) {
            report_text();
            return;
        }
        report("Debian Package v", false);
        writeln(h.version_);
        if (More)
        {
            deb_data_hdr dh;
            int os, dos;
            try
            {
                import std.conv : parse;
                string dps = isostr(h.ctl_filesize);
                os = parse!int(dps);
                file.seek(os, SEEK_CUR);
                scpy(file, &dh, dh.sizeof, false);
                string doss = isostr(dh.filesize);
                dos = parse!int(doss);
            }
            catch (Exception)
            {
                return;
            }
            writeln(isostr(h.ctl_file_ident), " - ", os / 1024, " KB");
            writeln(isostr(dh.file_ident), " - ", dos / 1024, " KB");
        }
    }
        return;

    case 0xDBEEABED: { // RPM Package
        struct rpm_hdr { align(1):
            char[4] magic;
            ubyte major, minor;
            ushort type;
            ushort archnum;
            char[66] name;
            ushort osnum;
            ushort signature_type;
            //char[16] reserved;
        }
        rpm_hdr h;
        scpy(file, &h, h.sizeof, true);
        report("RPM ", false);
        switch (h.type)
        {
            case 0: write("Binary"); break;
            case 0x100: write("Source"); break;
            default: write("Unknown type"); break;
        }
        write(" Package v");
        write(h.major, ".", h.minor, " \"", asciz(h.name), "\" for ");
        switch (h.osnum)
        {
            case 0x100: write("linux"); break;
            default: write("other"); break;
        }
        writeln(" platforms");
    }
        return;

    case 0x44415749, 0x44415750: {// "IWAD", "PWAD"
        int[2] b; // Doom reads as int
        file.rawRead(b);
        report(sig.idup, false);
        writefln(" holding %d entries at %Xh", b[0], b[1]);
        return;
    }

    case 0x6D736100: // "\0asm"
        report("WebAssembly file (wasm)");
        return;

    case 0x45555254: { // "TRUE"
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
    case 0x4A41574B: { // "KWAJ"
        struct kwaj_hdr { align(1):
            char[8] magic;
            ushort method; // compressed method
            ushort offset;
            ushort header; // header flag
        }

        kwaj_hdr h;
        scpy(file, &h, h.sizeof, true);

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

        const int ext = h.header & EXT, name = h.header & NAME;

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

    case 0x44445A53: { // "SZDD"
        struct szdd_hdr { align(1):
            char[8] magic;
            ubyte compression; // compressed mode, only 'A' is valid
            ubyte character; // filename end character (0=unknown)
            uint length; // unpacked
        }

        szdd_hdr h;
        scpy(file, &h, h.sizeof, true);

        report("MS-DOS ", false);

        if (h.compression == 'A')
            write("SZDD");
        else
            write("Non-valid SZDD");

        writeln(" Compressed file (SZDD)");
    }
        break;

    case 0x00020000:
        report("Lotus 1-2-3 spreadsheet (v1) file");
        return;

    case 0x001A0000: {
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

    case 0xF3030000:
        report("Amiga Hunk executable file");
        return;    

    case 0x49490000, 0x4D4D0000: // "\0\0II", "\0\0MM"
        report("Quark Express document");
        return;

    case 0x0000FEFF, 0xFFFE0000:
        report("UTF-32 text file with Byte-Order Mark (", false);
        if (s == 0x0000FEFF) writeln("LSB)");
        else  writeln("MSB)");
        return;

    case 0x30524448: { // "HDR0"
        struct trx_hdr { align(1):
            uint magic;
            uint length;
            uint crc;
            ushort flags;
            ushort version_;
        }

        trx_hdr h;
        scpy(file, &h, h.sizeof);

        if (h.version_ == 1 || h.version_ == 2) {
            report("TRX v", false);
            writefln("%d firmware (Length: %d, CRC32: %Xh)",
                h.version_, h.length, h.crc);
        }
        else
            report_unknown();
    }
        return;

    case 0x564D444B: { // "KDMV", VMDK vdisk
        struct SparseExtentHeader { align(1):
            uint magicNumber;
            uint version_;
            uint flags;
            ulong capacity;
            ulong grainSize;
            ulong descriptorOffset;
            ulong descriptorSize;
            uint numGTEsPerGT;
            ulong rgdOffset;
            ulong gdOffset;
            ulong overHead;
            ubyte uncleanShutdown; // "Bool"
            char singleEndLineChar;
            char nonEndLineChar;
            char doubleEndLineChar1;
            char doubleEndLineChar2;
            ushort compressAlgorithm;
            //ubyte[433] pad;
        }
        enum {
            COMPRESSED = 1 << 16
        }

        SparseExtentHeader h;
        scpy(file, &h, h.sizeof, true);

        report("VMware Disk image v", false);
        write(h.version_, ", ");

        //if (h.flags & COMPRESSED)
        switch (h.compressAlgorithm)
        {
        case 0: write("no"); break;
        case 1: write("DEFLATE"); break;
        default: write("unknown"); break;
        }
        write(" compression");

        if (h.uncleanShutdown)
            write(", unclean shutdown");

        writeln();

        if (More)
        {
            writefln("Capacity: %d Sectors", h.capacity);
            writefln("Overhead: %d Sectors", h.overHead);
            writefln("Grain size (Raw): %d Sectors", h.grainSize);
        }
    }
        return;

    case 0x44574F43: { // "COWD", ESXi COW
        enum COWDISK_MAX_PARENT_FILELEN = 1024;
        enum COWDISK_MAX_NAME_LEN = 60;
        enum COWDISK_MAX_DESC_LEN = 512;
        struct Root { align(1):
            uint cylinders;
            uint heads;
            uint sectors;
        }
        struct Child { align(1):
            char[COWDISK_MAX_PARENT_FILELEN] parentFileName;
            uint parentGeneration;
        }
        struct COWDisk_Header { align(1):
            //uint magicNumber;
            uint version_;
            uint flags;
            uint numSectors;
            uint grainSize;
            uint gdOffset;
            uint numGDEntries;
            uint freeSector;
            union {
                Root root;
                Child child;
            }
            uint generation;
            char[COWDISK_MAX_NAME_LEN] name;
            char[COWDISK_MAX_DESC_LEN] description;
            uint savedGeneration;
            char[8] reserved;
            uint uncleanShutdown;
            //char[396] padding;
        }
        COWDisk_Header h;
        scpy(file, &h, h.sizeof);
        if (h.flags != 3)
        {
            report_text();
            return;
        }
        const long size = h.numSectors * 512;
        report("ESXi COW disk image v", false);
        writeln(h.version_, ", ", formatsize(size), ", \"", asciz(h.name), "\"");

        if (More)
        {
            writeln("Cylinders: ", h.root.cylinders);
            writeln("Heads: ", h.root.heads);
            writeln("Sectors: ", h.root.sectors);
            //writeln("Child filename: ", asciz(h.u.child.parentFileName));
        }
    }
        return;

    case 0x656E6F63: { // "cone", conectix, VHD, values in big endian
        struct vhd_hdr { align(1):
            uint features;
            ushort major;
            ushort minor;
            ulong offset;
            uint timestamp;
            char[4] creator_app;
            ushort creator_major;
            ushort creator_minor;
            char[4] creator_os;
            ulong size_original;
            ulong size_current;
            ushort cylinders;
            ubyte heads;
            ubyte sectors;
            uint disk_type;
            uint checksum;
            ubyte[16] uuid;
            ubyte savedState;
            //ubyte[427] reserved;
        }
        enum {
            VHDMAGIC = "conectix",
            OS_WINDOWS = "Wi2k",
            OS_MAC = "Mac ",
        }
        enum {
            F_TEMPORARY = 1,
            F_RES = 2, // reserved, always 1
            D_FIXED = 2,
            D_DYNAMIC = 3,
            D_DIFF = 4,
        }
        file.rawRead(sig);
        if (sig != VHDMAGIC[4..$])
        {
            report_text();
            return;
        }
        vhd_hdr h;
        scpy(file, &h, h.sizeof);
        h.features = bswap(h.features);
        if ((h.features & F_RES) == 0)
        {
            report_text();
            return;
        }
        report("Microsoft VHD disk image v", false);
        write(bswap(h.major), ".", bswap(h.minor));

        h.disk_type = bswap(h.disk_type);
        switch(h.disk_type)
        {
            case D_FIXED: write(", Fixed"); break;
            case D_DYNAMIC: write(", Dynamic"); break;
            case D_DIFF: write(", Differencing"); break;
            default:
                if (h.disk_type < 7)
                    write(", Reserved (deprecated)");
                else
                    write(", Invalid type");
                break;
        }

        write(", ", h.creator_app, " v",
            bswap(h.creator_major), ".", bswap(h.creator_minor));

        switch (h.creator_os)
        {
            case OS_WINDOWS: write(" on Windows"); break;
            case OS_MAC:     write(" on macOS"); break;
            default: break;
        }

        h.size_current = bswap(h.size_current);
        h.size_original = bswap(h.size_original);
        if (h.size_current && h.size_original)
        {
            write(", ", formatsize(h.size_current), "/",
                formatsize(h.size_original), " used");
        }

        if (h.features & F_TEMPORARY)
            write(", Temporary");
        
        if (h.savedState)
            write(", Saved State");

        writeln();

        if (More)
        {
            write("UUID: ");
            writef("%02X", h.uuid[0]);
            for (uint i = 1; i < h.uuid.length; ++i)
                writef("-%02X", h.uuid[i]);
            writeln();
            writeln("Cylinders: ", h.cylinders);
            writeln("Heads: ", h.heads);
            writeln("Sectors: ", h.sectors);
        }
    }
        return;

    case 0x203C3C3C: { // "<<< ", VDI vdisk
    //https://forums.virtualbox.org/viewtopic.php?p=29266#p29266
        enum {
            VDI_OLDER = "Sun xVM VirtualBox Disk Image >>>",
            VDI = "Oracle VM VirtualBox Disk Image >>>"
        }
        enum VDIMAGIC = 0xBEDA107F;
        struct vdi_hdr { align(1):
            uint magic;
            ushort majorv;
            ushort minorv;
            uint hdrsize;
            uint type;
            uint flags;
            char[28] description;
        }
        struct svdi_hdr { align(1): // SEEK 0x150
            uint offsetBlock;
            uint offsetData;
            uint cylinders;
            uint heads;
            uint sectors;
            uint sectorSize;
            uint reserved;
            ulong diskSize;
            uint blockSize;
            uint extraBlockData;
            uint blocksInHDD;
            uint blocksAllocated;
            ubyte[16] vdi_uuid;
            ubyte[16] lastsnap_uuid;
            ubyte[16] parent_uuid;
        }
        const char[] magic = file.readln()[0..$-1];
        switch (magic)
        {
            case VDI, VDI_OLDER: break;
            default:
                report_text(); // Coincidence
                return;
        }
        vdi_hdr h;
        file.seek(0x40);
        scpy(file, &h, h.sizeof);
        if (h.magic != VDIMAGIC) {
            report_text(); // Coincidence
            return;
        }
        svdi_hdr sh;
        file.seek(0x150);
        scpy(file, &sh, sh.sizeof);
        report("VirtualBox VDI disk image v", false);
        write(h.majorv, ".", h.minorv, ", ");
        switch (h.type)
        {
            case 1: write("Dynamic"); break;
            case 2: write("Static"); break;
            default: write("Unknown type"); break;
        }
        writeln(", ", formatsize(sh.diskSize));
        if (More)
        {
            write("VDI UUID     : ");
            writef("%02X", sh.vdi_uuid[0]);
            for (uint i = 1; i < sh.vdi_uuid.length; ++i)
                writef("-%02X", sh.vdi_uuid[i]);
            writeln();
            write("LASTSNAP UUID: ");
            writef("%02X", sh.lastsnap_uuid[0]);
            for (uint i = 1; i < sh.lastsnap_uuid.length; ++i)
                writef("-%02X", sh.lastsnap_uuid[i]);
            writeln();
            write("PARENT UUID  : ");
            writef("%02X", sh.parent_uuid[0]);
            for (uint i = 1; i < sh.parent_uuid.length; ++i)
                writef("-%02X", sh.parent_uuid[i]);
            writeln();
            writeln("Cylinders: ", sh.cylinders);
            writeln("Heads: ", sh.heads);
            writeln("Sectors: ", sh.sectors);
            writeln("Sector size: ", sh.sectorSize);
            writeln("Block size: ", sh.blockSize);
        }
    }
        return;

    case 0xFB494651: { // "QFI\xFB", QCOW2, big endian
    //https://people.gnome.org/~markmc/qcow-image-format.html
    //http://git.qemu-project.org/?p=qemu.git;a=blob;f=docs/specs/qcow2.txt
        struct QCowHeader { align(1): //v1/v2, v3 has extra fields
            uint magic;
            uint version_;
            ulong backing_file_offset;
            uint backing_file_size;
            uint cluster_bits;
            ulong size; // in bytes
            uint crypt_method;
            uint l1_size;
            ulong l1_table_offset;
            ulong refcount_table_offset;
            uint refcount_table_clusters;
            uint nb_snapshots;
            ulong snapshots_offset;
        }
        enum {
            C_AES = 1,
        }

        QCowHeader h;
        scpy(file, &h, h.sizeof, true);

        report("QEMU QCOW2 disk image v", false);
        write(bswap(h.version_), ", ", formatsize(bswap(h.size)));

        switch (bswap(h.crypt_method))
        {
            case C_AES: write(", AES encrypted"); break;
            default: break;
        }

        writeln();

        if (More)
        {
            writeln("Snapshots: ", bswap(h.nb_snapshots));
        }
    }
        return;

    case 0x00444551: { // "QED\0", QED
    //http://wiki.qemu-project.org/Features/QED/Specification
        struct qed_hdr { align(1):
            uint magic;
            uint cluster_size;
            uint table_size;
            uint header_size;
            ulong features;
            ulong compat_features;
            ulong autoclear_features;
            ulong l1_table_offset;
            ulong image_size;
            uint backing_filename_offset;
            uint backing_filename_size;
        }
        enum {
            QED_F_BACKING_FILE = 1,
            QED_F_NEED_CHECK = 2,
            QED_F_BACKING_FORMAT_NO_PROBE = 4,
        }
        report("QEMU QED disk image, ", false);
        qed_hdr h;
        scpy(file, &h, h.sizeof, true);
        write(formatsize(h.image_size));

        if (h.features & QED_F_BACKING_FILE) {
            char[] bfn = new char[h.backing_filename_size];
            file.seek(h.backing_filename_offset);
            file.rawRead(bfn);
            write(", ");
            if (h.features & QED_F_BACKING_FORMAT_NO_PROBE)
                write("raw ");
            write("backing file: ", bfn);
        }

        if (h.features & QED_F_NEED_CHECK)
            write(", check needed");

        writeln();
    }
        return;

    /*case "With": { // WithoutFreeSpace -- Parallels HDD
        char[12]
        report("Parallels HDD disk image");
    }
        return;*/

    case 0x20584D50: { // "PMX "
        import s_models : scan_pmx;
        scan_pmx(file);
        return;
    }

    case 0x46494C46: // "FLIF"
        scan_flif(file);
        return;

    default:
        switch (sig[0..2])
        {
        case [0x1F, 0x9D]:
            report("Lempel-Ziv-Welch compressed archive (RAR/ZIP)");
            return;

        case [0x1F, 0xA0]:
            report("LZH compressed archive (RAR/ZIP)");
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
            report("Bitmap image file (BMP)");
            return;

        case [0x1F, 0x8B]:
            report("GZIP compressed file (gz)");
            return;

        case [0x30, 0x82]:
            report("DER encoded X.509 certificate (der)");
            return;

        default:
            switch (sig[0..3])
            {
            case "GIF":
                scan_gif(file);
                break;

            case "BZh":
                report("Bzip2 compressed file (bzip2)");
                return;

            case [0xEF, 0xBB, 0xBF]:
                report("UTF-8 text file with BOM");
                return;

            case "ID3":
                report("MPEG-2 Audio Layer III audio file with ID3v2 (MP3)");
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
                scan_etc(file);
                return;
            } // 3 Byte signatures
        } // 2 Byte signatures
    } // 4 Byte signatures
} // main

/// Report an unknown file type.
/// Params: filename = Filename in CLI phase
void report_unknown(string filename = null)
{
    if (ShowingName) {
        if (filename)
            write(filename, ": ");
        else
            write(CurrentFile.name, ": ");
    }
    
    writeln("Unknown type");
}

/// Report a text file.
// A few functions relies on this.
void report_text()
{
    report("Text file");
}

/*
 * Some Microsoft thing used for DeviceIoCtl.
 * Params:
 *   t = Device type
 *   f = Function
 *   m = Method
 *   a = Access
 * Returns: BOOL
 */
/*version (Windows)
uint CTL_CODE(uint d, uint f, uint m, uint a) {
    return ((d) << 16) | ((a) << 14) | ((f) << 2) | (m);
}*/

/// Report a symbolic link.
/// Params: linkname = Path to the link
void report_link(string linkname)
{
    if (ShowingName)
        write(linkname, ": ");

    //TODO: Symlink location
    // WINDOWS:
//https://msdn.microsoft.com/en-us/library/aa365511(v=VS.85).aspx

    write("Soft symbolic link");

    version (Windows)
    { // Obviously this won't work.
        /+import core.sys.windows.windows;
        import std.utf;
        import std.array;
        // WinIoCtl.h
        enum FILE_DEVICE_FILE_SYSTEM = 0x00000009;
        enum METHOD_BUFFERED = 0;
        enum FILE_ANY_ACCESS = 0;
        enum FSCTL_GET_REPARSE_POINT =
        CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 42, METHOD_BUFFERED, FILE_ANY_ACCESS);
        struct REPARSE_JUNCTION_DATA_BUFFER {
            ULONG ReparseTag;
            USHORT ReparseDataLength;
            USHORT Reserved;
            union {
                struct SymbolicLinkReparseBuffer{
                    USHORT SubstituteNameOffset;
                    USHORT SubstituteNameLength;
                    USHORT PrintNameOffset;
                    USHORT PrintNameLength;
                    ULONG  Flags;
                    WCHAR[1]  PathBuffer;
                }
                struct MountPointReparseBuffer{
                    USHORT SubstituteNameOffset;
                    USHORT SubstituteNameLength;
                    USHORT PrintNameOffset;
                    USHORT PrintNameLength;
                    WCHAR[1]  PathBuffer;
                }
                struct GenericReparseBuffer{
                    UCHAR[1] DataBuffer;
                }
            }
        }

        immutable wchar[] ws = linkname.byUTF!wchar().array;

        HANDLE f = CreateFile(&ws[0],
            GENERIC_READ | GENERIC_WRITE,
            0,
            NULL,
            OPEN_EXISTING,
            FILE_ATTRIBUTE_READONLY | FILE_FLAG_BACKUP_SEMANTICS,
            NULL
        );

        DWORD e = GetLastError;

        if (e)
        {
            writefln("Error %X", e);
            return;
        }

        //File f = File(linkname);
        DWORD bytesRet;

        REPARSE_JUNCTION_DATA_BUFFER rbuf;
        if (DeviceIoControl(f,
            FSCTL_GET_REPARSE_POINT,
            NULL,
            0,
            &rbuf,
            rbuf.sizeof,
            &bytesRet,
            NULL)) { // Not-zero (BOOL)
            writeln("!!!!! YES!? !!!!!!");
        } else {
            /*
                Usually returns 0x00001126
                ERROR_NOT_A_REPARSE_POINT
                The file or directory is not a reparse point.
            */
            writefln("ERROR: %08X (%d B ret)", GetLastError, bytesRet);
        }+/
        // Solution 2
        /*WIN32_FIND_DATA wd;

        OSVERSIONINFO winver;
        if (GetVersionEx(&winver))
        {
            if (winver.dwMajorVersion >= 6)
            {
                import std.utf : toUTF16z, count;
                wchar[MAX_PATH] ws;
                HANDLE = FindFirstFileNameW(
                    linkname.toUTF16z,
                    0,
                    MAX_PATH,
                    &ws[0]
                );

                writeln(ws);
            }
        }*/
    }
    version (Posix)
    {
        import core.stdc.stdio : printf;
        import core.sys.posix.stdlib : realpath;
        char* p = realpath(&linkname[0], cast(char*)0);
        if (p) printf(" to %s", p);
    }
    writeln;
}

/**
 * Report to the user information.
 *
 * If the newline is false, the developper must end the information with a new line manually.
 * Params:
 *   type = Type/format of file (String)
 *   nl = Print newline
 */
void report(string type, bool nl = true)
{
    if (ShowingName)
        writef("%s: ", CurrentFile.name);

    write(type);

    if (nl)
        writeln();
}