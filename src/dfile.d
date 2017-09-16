/*
 * dfile.d : Where the adventure begins.
 */

module dfile;

import std.stdio;
import s_elf    : scan_elf;
import s_fatelf : scan_fatelf;
import s_mz     : scan_mz;
import s_mach   : scan_mach,
    MH_MAGIC, MH_MAGIC_64, MH_CIGAM, MH_CIGAM_64, FAT_MAGIC, FAT_CIGAM;
import s_models : scan_pmx;
import s_pst    : scan_pst, PST_MAGIC;
import Etc      : scan_etc;
import s_images : scan_bpg, scan_png, scan_flif, scan_gif;
import utils;

bool More, /// -m : More flag
     ShowName, /// -s : Show name flag
     Base10; /// -b : Base 10 flag
FILE* fp; /// Current file handle.
string filename; /// Current filename.

/**
 * Prints debugging message with a FILE@LINE: MSG formatting.
 * Params:
 *   msg = Message
 *   line = Source line (automatic)
 *   file = Source file (automatic)
 */
debug void dbg(string msg, int line = __LINE__, string file = __FILE__) {
    dbgl(msg, line, file);
    printf("\n");
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
    printf("%s@L%d: %s", &baseName(file)[0], line, &msg[0]);
}

/// Scanner entry point.
void scan() {
    uint s;
    if (fread(&s, 4, 1, fp) != 1) {
        report("Empty file");
        return;
    }
    version (BigEndian) s = bswap32(s);

    debug printf("Magic: %08X\n", s);

    switch (s) {
    /*case "PANG": // PANGOLIN SECURE -- Pangolin LD2000
        printf("LD2000 Frame file (LDS)");
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
        fread(&b, 12, 1, fp);
        switch (b[0..4]) {
        case "MSIS":
            report("Microsoft Money file");
            return;
        case "Stan":
            switch (b[8..12]) {
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
            if (b[0] == 0)
                report("TrueType font file");
            else
                report("Palm Desktop Data File (Access format)");
            return;
        }
    }

    case 0x4D53454E: { // "NESM"
        char[1] b;
        fread(&b, 1, 1, fp);
        switch (b) {
        case x"1A": {
            struct nesm_hdr { align(1):
                //char[5] magic;
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
            scpy(&h, h.sizeof);

            if (h.flag & 0b10)
                report("Dual NTSC/PAL", false);
            else if (h.flag & 1)
                report("NSTC", false);
            else
                report("PAL", false);

            printf(" Nintendo Sound Format, %d songs, ", h.total_song);

            if (h.chip & 1)
                printf("VRCVI, ");
            if (h.chip & 0b10)
                printf("VRCVII, ");
            if (h.chip & 0b100)
                printf("FDS, ");
            if (h.chip & 0b1000)
                printf("MMC5, ");
            if (h.chip & 0b1_0000)
                printf("Namco 106, ");
            if (h.chip & 0b10_0000)
                printf("Sunsoft FME-07, ");

            printf("\"%s - %s\", (c) %s\n",
                &h.song_artist[0], &h.song_name[0], &h.song_copyright[0]);
            }
            return;
        default:
            report_unknown();
            return;
        }
    }

    case 0x4350534B: { // "KSPC"
        char[1] b;
        fread(&b, 1, 1, fp);
        switch (b) {
            case x"1A": {
                struct spc2_hdr { align(1):
                    //char[5] magic;
                    ubyte major, minor;
                    ushort number;
                }

                spc2_hdr h;
                scpy(&h, h.sizeof);

                report("SNES SPC2 v", false);
                printf("%d.%d, %d of SPC entries\n", h.major, h.minor, h.number);
            }
                return;
            default:
                report_unknown();
                return;
        }
    }

    case 0x00010000:
        report("Icon file, ICO format");
        return;

    case 0x08000100:
        report("Ventura Publisher/GEM VDI Image Format Bitmap file");
        return;

    case 0x4B434142: // "BACK"
        fread(&s, 4, 1, fp);
        switch (s) {
        case 0x454B494D: // "MIKE"
            fread(&s, 4, 1, fp);
            switch (s) {
            case 0x4B534944: // "DISK"
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
        fread(&b, 6, 1, fp);
        switch (b) {
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
        report("Rob Northen Compressed archive v", false);
        final switch (s & 0xFF000000) { // Very lazy
        case 1: printf("2\n"); break;
        case 2: printf("1\n"); break;
        }
        return;

    case 0x58504453, 0x53445058: // "SDPX", "XPDS"
        report("SMPTE DPX image");
        return;

    case 0x01312F76:
        report("OpenEXR image");
        return;

    case 0xFB475042: // BPGû
        scan_bpg;
        return;

    case 0xDBFFD8FF, 0xE0FFD8FF, 0xE1FFD8FF:
        report("Joint Photographic Experts Group image");
        return;

    case 0xCEA1A367:
        report("IMG archive");
        return;

    //case "GBLE", "GBLF", "GBLG", "GBLI", "GBLS", "GBLJ":
    case 0x454C4247, 0x464C4247, 0x474C4247, 0x494C4247, 0x534C4247, 0x4A4C4247:
        report("GTA Text (GTA2+) file, ", false);
        final switch (s) {
        case 0x454C4247: writeln("English");  break; // 'E'
        case 0x464C4247: writeln("French");   break; // 'F'
        case 0x474C4247: writeln("German");   break; // 'G'
        case 0x494C4247: writeln("Italian");  break; // 'I'
        case 0x534C4247: writeln("Spanish");  break; // 'S'
        case 0x4A4C4247: writeln("Japanese"); break; // 'J'
        }
        return;

    case 0x47585432: { // "2TXG"
        uint b;
        fread(&b, 4, 1, fp);
        report("GTA Text 2 file with ", false);
        printf("%d entries\n", bswap32(b)); // Byte swapped
    }
        return;

    //case "RPF0", "RPF2", "RPF3", "RPF4", "RPF6", "RPF7": {
    case 0x30465052, 0x32465052, 0x33465052, 0x34465052, 0x36465052, 0x37465052: {
        struct rpf_hdr { align(1):
            //int magic;
            int tablesize;
            int numentries;
            int unknown0;
            int encrypted;
        }
        rpf_hdr h;
        scpy(&h , h.sizeof);
        report("RPF ", false);
        if (h.encrypted)
            printf("encrypted");
        printf("archive v%c (", (s >>> 24) + 0x30);
        final switch (s) {
        case 0x30465052: printf("Table Tennis"); break;
        case 0x32465052: printf("GTA IV"); break;
        case 0x33465052: printf("GTA IV:A&MC:LA"); break;
        case 0x34465052: printf("Max Payne 3"); break;
        case 0x36465052: printf("Red Dead Redemption"); break;
        case 0x37465052: printf("GTA V"); break;
        }
        printf("), %d entries\n", h.numentries);
    }
        return;

    case 0x14000000, 0x18000000, 0x1C000000, 0x20000000: {
        char[8] b;
        fread(&b, 8, 1, fp);
        switch (b[0..4]) {
        case "ftyp":
            switch (b[4..8]) {
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
                switch (b[4..7]) {
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
        fseek(fp, 8, SEEK_SET);
        fread(&b, 4, 1, fp);
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

    case 0x58444E49: // "INDX"
        report("AmiBack backup index file");
        return;

    case 0x50495A4C: // "LZIP"
        report("LZIP Archive");
        return;

    // Only the last signature is within the doc.
    case 0x04034B42, 0x06054B42, 0x08074B42, 0x04034B50: {
        struct pkzip_hdr { align(1): // PKWare ZIP
            //uint magic;
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
        scpy(&h, h.sizeof);

        debug writeln("FNLENGTH: ", formatsize(h.fnlength));

        report("PKWare ZIP ", false); // JAR, ODF, OOXML, EPUB

        switch (h.compression) {
        case 0: printf("Uncompressed"); break;
        case 1: printf("Shrunk"); break;
        case 2: .. // 2 to 5
        case 5: printf("Reduced by %d", h.compression - 1); break;
        case 6: printf("Imploded"); break;
        case 8: printf("Deflated"); break;
        case 9: printf("Enhanced Deflated"); break;
        case 10: printf("DCL Imploded (PKWare)"); break;
        case 12: printf("BZIP2"); break;
        case 14: printf("LZMA"); break;
        case 18: printf("IBM TERSE"); break;
        case 19: printf("IBM LZ77 z"); break;
        case 98: printf("PPMd Version I, Rev 1"); break;
        default: printf("(Unknown type)"); return;
        }

        printf(" archive (v%d.%d), ", h.version_ / 10, h.version_ % 10);

        if (h.fnlength > 0) {
            ubyte[] file = new ubyte[h.fnlength];
            fread(&file[0], h.fnlength, 1, fp);
            printf("%s, ", &file[0]);
        }

        write(formatsize(h.csize), "/", formatsize(h.usize));

        enum {
            ENCRYPTED = 1, // 1
            ENHANCED_DEFLATION = 16, // 4
            COMPRESSED_PATCH = 32, // 5, data
            STRONG_ENCRYPTION = 64, // 6
        }

        if (h.flag & ENCRYPTED)
            printf(", Encrypted");

        if (h.flag & STRONG_ENCRYPTION)
            printf(", Strongly encrypted");

        if (h.flag & COMPRESSED_PATCH)
            printf(", Compression patch");

        if (h.flag & ENHANCED_DEFLATION)
            printf(", Enhanced deflation");

        writeln;

        if (More) {
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
    }
        return;

    case 0x21726152: { // "Rar!"
        char[3] b;
        fread(&b, 3, 1, fp);
        switch (b) {
        case x"1A 07 01": //TODO: http://www.rarlab.com/technote.htm
            report("RAR archive v5.0+");
            return;
        default:
            if (b == x"1A 07 00")
                report("RAR archive v1.5+");
            else
                report_unknown();
            return;
        }
    }

    case 0x464C457F: // "\x7FELF"
        scan_elf();
        return;

    case 0x010E70FA: // FatELF - 0x1F0E70FA
        scan_fatelf();
        return;

    case 0x474E5089: // "\x89PNG"
    // Note: Uncommenting this code will require to remove the rest of the
    //       magic from the struct
        /*fread(&s, 4, 1, fp);
        switch (s) {
        case 0x0A1A0A0D: scan_png(); return;
        default: report_unknown(); return;
        }*/
        scan_png;
        return;

    case MH_MAGIC, MH_MAGIC_64, MH_CIGAM, MH_CIGAM_64, FAT_MAGIC, FAT_CIGAM:
        scan_mach(s);
        return;

    case 0x53502125: // "%!PS"
        report("PostScript document");
        return;

    case 0x46445025: { // "%PDF"
        ubyte[5] b; // b[4] inits to 0
        fread(&b, 4, 1, fp);
        report("PDF", false);
        printf("%s document", &b);
    }
        return;

    case 0x75B22630: {
        char[12] b;
        fread(&b, 12, 1, fp);
        switch (b) {
        case x"8E 66 CF 11 A6 D9 0 AA 0 62 CE 6C":
            report("Advanced Systems Format file (ASF, WMA, WMV)");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case 0x49445324: // "$SDI"
        fread(&s, 4, 1, fp);
        switch (s) {
        case 0x31303030:
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
        scpy(&h, h.sizeof);
        report("Ogg audio file v", false);
        printf("%d with %d segments\n", h.version_, h.pages);

        if (More) {
            printf("CRC32: %08X\n", h.crc32);
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
        scpy(&h, h.sizeof);
        report("FLAC audio file", false);
        if ((h.header & 0xFF) == 0) { // Big endian. Not a fan.
            const int bits = ((h.stupid[8] & 1) << 4 | (h.stupid[9] >>> 4)) + 1;
            const int chan = ((h.stupid[8] >>> 1) & 7) + 1;
            const int rate =
                ((h.stupid[6] << 12) | h.stupid[7] << 4 | h.stupid[8] >>> 4);
            printf(", %d Hz, %d-bit, %d channels\n", rate, bits, chan);
            if (More) {
                printf("MD5: ");
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
        scpy(&h, h.sizeof);
        report("Photoshop Document v", false);
        printf("%d, %d x %d, %d-bit ",
            bswap16(h.version_), bswap32(h.width), bswap32(h.height), bswap16(h.depth));
        switch (bswap16(h.colormode)) {
        case 0: printf("Bitmap"); break;
        case 1: printf("Grayscale"); break;
        case 2: printf("Indexed"); break;
        case 3: printf("RGB"); break;
        case 4: printf("CMYK"); break;
        case 7: printf("Multichannel"); break;
        case 8: printf("Duotone"); break;
        case 9: printf("Lab"); break;
        default: printf("Unknown type"); break;
        }
        printf(" image, %d channel(s)\n", bswap16(h.channels));
    }
        return;

    case 0x46464952: // "RIFF", most MP2 files
        fseek(fp, 8, SEEK_SET);
        fread(&s, 4, 1, fp);
        switch (s) {
        case 0x45564157: { // "WAVE"
            //http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html
            struct fmt_chunk { align(1):
                //char[4] id;
                uint cksize;
                ushort format;
                ushort channels;
                uint samplerate; // Blocks per second
                uint datarate; // Bytes/s
                ushort blockalign;
                ushort samplebits; // Bits per sample
                ushort extensionsize;
                ushort nbvalidbits;
                uint speakmask; // Speaker position mask
                char[16] guid;
            }
            enum FMT_CHUNK = 0x20746D66; // "fmt ";
            enum { // Types
                PCM = 1,
                IEEE_FLOAT = 3,
                ALAW = 6,
                MULAW = 7,
                _MP2 = 0x55, // Undocumented
                EXTENSIBLE = 0xFFFE
            }
            fread(&s, 4, 1, fp);
            if (s != FMT_CHUNK) // Time to find the right chunk type
                do { // Skip useless chunks
                    fread(&s, 4, 1, fp); // Chunk length
                    if (fseek(fp, s, SEEK_CUR)) {
                        report_unknown;
                        return;
                    }
                    fread(&s, 4, 1, fp);
                } while (s != FMT_CHUNK);
            fmt_chunk h;
            scpy(&h, h.sizeof);
            report("WAVE audio file (", false);
            switch (h.format) {
                case PCM: printf("PCM"); break;
                case IEEE_FLOAT: printf("IEEE Float"); break;
                case ALAW:  printf("8-bit ITU G.711 A-law"); break;
                case MULAW: printf("8-bit ITU G.711 u-law"); break;
                case EXTENSIBLE:
                    printf("EXTENDED");
                    if (More) {
                        printf(":");
                        print_array(&h.guid[0], h.guid.length);
                    }
                    break;
                case _MP2:  printf("MPEG-1 Audio Layer II"); break;
                default: printf("Unknown type)\n"); return;
            }
            printf(") %d Hz, %d kbps, %d-bit, ",
                h.samplerate, h.datarate / 1024 * 8, h.samplebits);
            switch (h.channels) {
                case 1: writeln("Mono"); break;
                case 2: writeln("Stereo"); break;
                default: writeln(h.channels, " channels"); break;
            }
        }
            return;
        case 0x20495641: // "AVI "
            report("Audio Video Interface video (avi)");
            return;
        default:
            report_unknown();
            return;
        }

    case 0x504D4953: // "SIMP"
        fread(&s, 4, 1, fp);
        switch (s) {
        case 0x2020454C: // "LE  "
            report("Flexible Image Transport System (FITS)");
            return;
        default:
            report_unknown();
            return;
        }

    case 0x6468544D: { // "MThd", MIDI, Big Endian
        struct midi_hdr { align(1):
            //char[4] magic;
            uint length;
            ushort format, number, division;
        }

        midi_hdr h;
        scpy(&h, h.sizeof);

        report("MIDI, ", false);

        switch (bswap16(h.format)) {
        case 0: printf("Single track"); break;
        case 1: printf("Multiple tracks"); break;
        case 2: printf("Multiple songs"); break;
        default: printf("Unknown format"); return;
        }

        const ushort div = bswap16(h.division);
        printf(": %d tracks at ", bswap16(h.number));
        if (div & 0x8000) // Negative, SMPTE units
            printf("%d ticks/frame (SMPTE: %d)\n", div & 0xFF, div >>> 8 & 0xFF);
        else // Ticks per beat
            printf("%d ticks/quarter-note\n", div);
    }
        return;

    case 0xE011CFD0: // Then follows 0xE11AB1A1
        struct cfb_header { align(1):
            //ulong magic;
            uint magic;
            ubyte[16] clsid; // CLSID_NULL
            ushort minor;
            ushort major;
            ushort byte_order;
            ushort shift; /// Sector Shift
            ushort mini_shift; /// Mini Sector Shift
            ubyte[6] res;
            uint dir_sectors;
            uint fat_sectors;
            uint first_dir_sector;
            uint trans_sig; /// Transaction Signature Number
            uint mini_stream_cutsize;
            uint first_mini_fat_loc;
            uint mini_fat_sectors; /// Number of Mini FAT Sectors
            uint first_difat_loc; /// First DIFAT Sector Location
            uint difat_sectors; /// Number of DIFAT Sectors
            //ubyte[436] difat;
        }
        cfb_header h;
        scpy(&h, h.sizeof);
        report("Compound File Binary format document ", false);
        with (h) {
            printf("v%d.%d, %d FAT sectors\n", major, minor, fat_sectors);
            if (More) {
                printf("%d directory sectors at %Xh\n",
                    dir_sectors, first_dir_sector);
                if (trans_sig)
                    printf("transaction signature, %Xh", trans_sig);
                printf("%d DIFAT sectors at %Xh\n",
                    difat_sectors, first_difat_loc);
                printf("%d mini FAT sectors at %Xh\n",
                    mini_fat_sectors, first_mini_fat_loc);
            }
        }
        return;

    case 0x0A786564: // "dex\x0A", then follows "035\0"
        report("Dalvik Executable");
        return;

    case 0x34327243: // "Cr24"
        report("Google Chrome extension or packaged app (crx)");
        return;

    case 0x33444741: // "AGD3"
        report("FreeHand 8 document (fh8)");
        return;

    case 0x00000705: {
        char[6] b;
        fread(&b, 6, 1, fp);
        switch (b) {
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

    case 0x21726178: // "xar!"
        report("eXtensible ARchive format (xar)");
        return;

    case 0x434F4D50: // "PMOC"
        fread(&s, 4, 1, fp);
        switch (s) {
        case 0x434F4D43: // "CMOC"
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

    case 0x004D4344: // "DCM\0", followed by "PA30"
        report("Windows Update Binary Delta Compression file");
        return;

    case 0xAFBC7A37: // Followed by [0x27, 0x1C]
        report("7-Zip compressed file (7z)");
        return;

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
        scpy(&h, h.sizeof);
        report("Microsoft Cabinet archive v", false);
        printf("%d.%d, ", h.major, h.minor);
        write(formatsize(h.size));
        printf(", %d files and %d folders\n", h.files, h.folders);
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
        scpy(&h, h.sizeof);
        report("InstallShield CAB archive", false);
        switch (h.version_) {
        case LEGACY:    printf(" (Legacy)");  break;
        case v2_20_905: printf(" v2.20.905"); break;
        case v3_00_065: printf(" v3.00.065"); break;
        case v5_00_000: printf(" v5.00.000"); break;
        default: writef(" (Version: 0x%08X)", h.version_); break;
        }
        printf(" at %Xh\n", h.desc_offset);
    }
        return;

    case 0xA3DF451A:
        report("Matroska media container (mkv, webm)");
        return;

    case 0x204C494D: // "MIL "
        report(`"SEAN : Session Analysis" Training file`);
        return;

    case 0x54265441: // "AT&T"
        fread(&s, 4, 1, fp);
        switch (s) {
        case 0x4D524F46: // "FORM"
            fseek(fp, 4, SEEK_CUR);
            fread(&s, 4, 1, fp);
            switch (s) {
            case 0x55564A44: // "DJVU"
                report("DjVu document, single page");
                return;
            case 0x4D564A44: // "DJVM"
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
        scpy(&h, h.sizeof, true);
        if (h.file_iden != DEBIANBIN) {
            report_text();
            return;
        }
        report("Debian Package v", false);
        writeln(h.version_);
        if (More) {
            deb_data_hdr dh;
            int os, dos;
            try {
                import std.conv : parse;
                string dps = isostr(h.ctl_filesize);
                os = parse!int(dps);
                fseek(fp, os, SEEK_CUR);
                scpy(&dh, dh.sizeof, false);
                string doss = isostr(dh.filesize);
                dos = parse!int(doss);
            } catch (Exception) {
                return;
            }
            writeln("%s - %s KB", isostr(h.ctl_file_ident), os / 1024);
            writeln("%s - %s KB", isostr(dh.file_ident), dos / 1024);
        }
    }
        return;

    case 0xDBEEABED: { // RPM Package
        struct rpm_hdr { align(1):
            //char[4] magic;
            ubyte major, minor;
            ushort type;
            ushort archnum;
            char[66] name;
            ushort osnum;
            ushort signature_type;
            //char[16] reserved;
        }
        rpm_hdr h;
        scpy(&h, h.sizeof);
        report("RPM ", false);
        switch (h.type) {
            case 0: printf("Binary"); break;
            case 0x100: printf("Source"); break;
            default: printf("Unknown type"); break;
        }
        printf(" Package v");
        printf(`%d.%d, "%s", `, h.major, h.minor, &h.name[0]);
        switch (h.osnum) {
            case 0x100: printf("linux"); break;
            default: printf("other"); break;
        }
        writeln(" platforms");
    }
        return;

    case 0x44415749, 0x44415750: {// "IWAD", "PWAD"
        int[2] b; // Reads as ints.
        fread(&b, 8, 1, fp);
        if (0x44415750) // PWAD
            report("PWAD", false);
        else
            report("IWAD", false);
        printf(" holding %d entries at %Xh\n", b[0], b[1]);
        return;
    }

    case 0x6D736100: { // "\0asm", WebAssembly binary
        // http://webassembly.org/docs/binary-encoding/
        report("WebAssembly file (wasm) v", false);
        ubyte ver;
        fread(&ver, 1, 1, fp);
        printf("%d binary file\n", ver);
        return;
    }

    case 0x45555254: { // "TRUE"
        char[12] b;
        fread(&b, 12, 1, fp);
        switch (b) {
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
        scpy(&h, h.sizeof, true);

        report("MS-DOS ", false);

        switch (h.method) {
        case 0: printf("Non-compressed"); break;
        case 1: printf("FFh-XOR'd data"); break;
        case 2: printf("Regular SZDD Compressed"); break;
        case 3: printf(`LZ + Huffman "Jeff Johnson" Compressed`); break;
        case 4: printf("MS-ZIP Compressed"); break;
        default: printf("Unknown compression");
        }

        printf(" file (KWAJ)");

        if (h.offset)
            printf(" (offset:%Xh)", h.offset);

        enum : ushort {  // Header flags
            ULENGHT = 1, // 4 bytes, uncompressed data length
            UNKNOWN = 2, // 2 bytes
            DLENGHT = 4, // 2 bytes, data length?
            NAME = 8,    // ASCIZ, filename
            EXT = 0x10,  // ASCIZ, extension
        }

        const int ext = h.header & EXT, name = h.header & NAME;

        if (ext || name) {
            int offset;
            if (h.header & ULENGHT) offset += 4;
            if (h.header & UNKNOWN) offset += 2;
            if (h.header & DLENGHT) offset += 2;

            if (offset) fseek(fp, offset, SEEK_CUR);

            printf(" Out:");

            int c;

            if (name)
                while ((c = getc(fp)) != 0)
                    putchar(c);
            printf(".");
            if (ext)
                while ((c = getc(fp)) != 0)
                    putchar(c);
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
        scpy(&h, h.sizeof, true);

        report("MS-DOS ", false);

        if (h.compression == 'A')
            printf("SZDD");
        else
            printf("Non-valid SZDD");

        printf(" compressed file\n");
    }
        break;

    case 0x00020000:
        report("Lotus 1-2-3 spreadsheet (v1) file");
        return;

    case 0x001A0000: {
        char[3] b;
        fread(&b, 3, 1, fp);
        switch (b) {
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
        if (s == 0xFEFF) printf("LSB)\n");
        else printf("MSB)\n");
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
        scpy(&h, h.sizeof);

        if (h.version_ == 1 || h.version_ == 2) {
            report("TRX v", false);
            printf("%d firmware (Length: %d, CRC32: %Xh)\n",
                h.version_, h.length, h.crc);
        } else
            report_unknown();
    }
        return;

    case 0x564D444B: { // "KDMV", VMDK vdisk
        struct SparseExtentHeader { align(1):
            //uint magicNumber;
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
        //enum COMPRESSED = 1 << 16;

        SparseExtentHeader h;
        scpy(&h, h.sizeof);

        report("VMware Disk image v", false);
        printf("%d, ", h.version_);

        //if (h.flags & COMPRESSED)
        switch (h.compressAlgorithm) {
        case 0: printf("no"); break;
        case 1: printf("DEFLATE"); break;
        default: printf("unknown"); break;
        }
        printf(" compression");

        if (h.uncleanShutdown)
            printf(", unclean shutdown");

        writeln();

        if (More) {
            printf("Capacity: %d Sectors\n", h.capacity);
            printf("Overhead: %d Sectors\n", h.overHead);
            printf("Grain size (Raw): %d Sectors\n", h.grainSize);
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
        scpy(&h, h.sizeof);
        if (h.flags != 3) {
            report_text();
            return;
        }
        const long size = h.numSectors * 512;
        report("ESXi COW disk image v", false);
        string cows = formatsize(size);
        printf("%d, %s, \"%s\"\n",
            h.version_, &cows[0], &h.name[0]);

        if (More) {
            printf("Cylinders: %d\n", h.root.cylinders);
            printf("Heads: %d\n", h.root.heads);
            printf("Sectors: %d\n", h.root.sectors);
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
        fread(&s, 4, 1, fp);
        if (s != 0x78697463) { // "ctix"
            report_text();
            return;
        }
        vhd_hdr h;
        scpy(&h, h.sizeof);
        h.features = bswap32(h.features);
        if ((h.features & F_RES) == 0) {
            report_text();
            return;
        }
        report("Microsoft VHD disk image v", false);
        printf("%d.%d, ", bswap16(h.major), bswap16(h.minor));

        h.disk_type = bswap32(h.disk_type);
        switch(h.disk_type) {
            case D_FIXED: printf("Fixed"); break;
            case D_DYNAMIC: printf("Dynamic"); break;
            case D_DIFF: printf("Differencing"); break;
            default:
                if (h.disk_type < 7)
                    printf("Reserved (deprecated)");
                else
                    printf("Invalid type");
                break;
        }

        printf(", %s v%d.%d on ",
            &h.creator_app[0], bswap16(h.creator_major), bswap16(h.creator_minor));

        switch (h.creator_os) {
            case OS_WINDOWS: printf("Windows"); break;
            case OS_MAC:     printf("macOS"); break;
            default: printf("Unknown"); break;
        }
/* TODO: Fix VHD Size
        h.size_current = bswap(h.size_current);
        h.size_original = bswap(h.size_original);
        if (h.size_current && h.size_original) {
            writef(", %s/%s used",
                formatsize(h.size_current), formatsize(h.size_original));
        }
*/
        if (h.features & F_TEMPORARY)
            printf(", Temporary");

        if (h.savedState)
            printf(", Saved State");

        writeln();

        if (More) {
            printf("UUID: ");
            print_array(&h.uuid[0], h.uuid.length);
            printf("Cylinders: %d\n", h.cylinders);
            printf("Heads: %d\n", h.heads);
            printf("Sectors: %d\n", h.sectors);
        }
    }
        return;

//TODO: Move all virtualdisks-related scanning to another source file.

    case 0x203C3C3C: { // "<<< ", Oracle VDI vdisk
        enum {
            VDI_SUN = "Sun xVM VirtualBox Disk Image >>>\n",
            VDI =     "Oracle VM VirtualBox Disk Image >>>\n"
        }
        enum VDIMAGIC = 0xBEDA107F, VDI_IMAGE_COMMENT_SIZE = 256;
        struct vdi_hdr { align(1):
        // Should also include char[64] but it's faster to just "read line"
            uint magic;
            ushort majorv;
            ushort minorv;
        }
        struct VDIDISKGEOMETRY { align(1):
            uint cCylinders;
            uint cHeads;
            uint cSectors;
            uint cbSector;
        }
        struct VDIHEADER0 { align(1): // Major v0
            uint u32Type;
            uint fFlags;
            char[VDI_IMAGE_COMMENT_SIZE] szComment;
            VDIDISKGEOMETRY LegacyGeometry;
            ulong cbDisk;
            uint cbBlock;
            uint cBlocks;
            uint cBlocksAllocated;
            ubyte[16] uuidCreate;
            ubyte[16] uuidModify;
            ubyte[16] uuidLinkage;
        }
        struct VDIHEADER1 { align(1): // Major v1
            uint cbHeader;
            uint u32Type;
            uint fFlags;
            char[VDI_IMAGE_COMMENT_SIZE] szComment;
            uint offBlocks;
            uint offData;
            VDIDISKGEOMETRY LegacyGeometry;
            uint u32Dummy;
            ulong cbDisk;
            uint cbBlock;
            uint cbBlockExtra;
            uint cBlocks;
            uint cBlocksAllocated;
            ubyte[16] uuidCreate;
            ubyte[16] uuidModify;
            ubyte[16] uuidLinkage;
            ubyte[16] uuidParentModify;
        }
        fseek(fp, 64, SEEK_SET); // Skip description
        vdi_hdr h;
        scpy(&h, h.sizeof);
        if (h.magic != VDIMAGIC) {
            report_text(); // Coincidence
            return;
        }
        report("VirtualBox VDI disk image v", false);
        printf("%d.%d, ", h.majorv, h.minorv);
        VDIHEADER1 sh;
        switch (h.majorv) { // Use latest major version natively
            case 1:
                scpy(&sh, sh.sizeof);
                break;
            case 0: {
                VDIHEADER0 t;
                scpy(&t, t.sizeof);
                sh.cbDisk = t.cbDisk;
                sh.u32Type = t.u32Type;
                sh.uuidCreate = t.uuidCreate;
                sh.uuidModify = t.uuidModify;
                sh.uuidLinkage = t.uuidLinkage;
                sh.LegacyGeometry = t.LegacyGeometry;
            }
                break;
            default: return;
        }
        switch (sh.u32Type) {
            case 1: printf("Dynamic"); break;
            case 2: printf("Static"); break;
            default: printf("Unknown type"); break;
        }
        writeln(", ", formatsize(sh.cbDisk), " capacity");
        if (More) {
            printf("Create UUID : ");
            print_array(&sh.uuidCreate[0], 16);
            printf("Modify UUID : ");
            print_array(&sh.uuidModify[0], 16);
            printf("Link UUID   : ");
            print_array(&sh.uuidLinkage[0], 16);
            if (h.majorv >= 1) {
                printf("ParentModify UUID: ");
                print_array(&sh.uuidParentModify[0], 16);
                writeln("Header size: ", sh.cbHeader);
            }
            writeln("Cylinders (Legacy): ", sh.LegacyGeometry.cCylinders);
            writeln("Heads (Legacy): ", sh.LegacyGeometry.cHeads);
            writeln("Sectors (Legacy): ", sh.LegacyGeometry.cSectors);
            writeln("Sector size (Legacy): ", sh.LegacyGeometry.cbSector);
        }
    }
        return;

    case 0xFB494651: { // "QFI\xFB", QCOW2, big endian
    //https://people.gnome.org/~markmc/qcow-image-format.html
    //http://git.qemu-project.org/?p=qemu.git;a=blob;f=docs/specs/qcow2.txt
        struct QCowHeader { align(1): //v1/v2, v3 has extra fields
            //uint magic;
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
        enum C_AES = 1;

        QCowHeader h;
        scpy(&h, h.sizeof);

        report("QEMU QCOW2 disk image v", false);
        write(bswap32(h.version_), ", ", formatsize(bswap64(h.size)), " capacity");

        switch (bswap32(h.crypt_method)) {
            case C_AES: printf(", AES encrypted"); break;
            default: break;
        }

        writeln();

        if (More) {
            printf("Snapshots: %d\n", bswap32(h.nb_snapshots));
        }
    }
        return;

    case 0x00444551: { // "QED\0", QED
    //http://wiki.qemu-project.org/Features/QED/Specification
        struct qed_hdr { align(1):
            //uint magic;
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
        scpy(&h, h.sizeof);
        write(formatsize(h.image_size));

        if (h.features & QED_F_BACKING_FILE) {
            //char[] bfn = new char[h.backing_filename_size];
            fseek(fp, h.backing_filename_offset, SEEK_SET);
            char* c;
            fgets(c, h.backing_filename_offset, fp);
            printf(", ");
            if (h.features & QED_F_BACKING_FORMAT_NO_PROBE)
                printf("raw ");
            printf("backing file: ", c);
        }

        if (h.features & QED_F_NEED_CHECK)
            printf(", check needed");

        writeln();
    }
        return;

    case 0x0D730178, 0x6d697368: // Apple DMG disk image
        report("Apple Disk Image file (dmg)");
        return;

    case 0x6B6F6C79: { // "koly", Apple DMG disk image
//TODO: Continue Apple DMG
//https://www.virtualbox.org/browser/vbox/trunk/src/VBox/Storage/DMG.cpp
// At the end of the file?!
        /*struct dmg_header { align(1):
            //uint magic;
            uint version_;
            uint footer; /// sizeof(dmg_header)
            uint flags;
            ulong data_offset;
            ulong data_size;
            ulong res_offset;
            ulong res_size;
            uint segmentnum;
            uint nbsegment;
            uint segmentid;

        }
        dmg_header h;
        scpy(&h, h.sizeof);*/
        report("Apple Disk Image file (dmg)");
    }
        return;

    /*case 0x6d697368: // "mish", Apple DMG disk image

        return;*/

    //TODO: Parallels HDD (Lacks verification/documentation)
    /*case "With": { // WithoutFreeSpace -- Parallels HDD
        char[12]
        report("Parallels HDD disk image");
        return;
    }*/

    case 0x20584D50: // "PMX "
        scan_pmx();
        return;

    case 0x46494C46: // "FLIF"
        scan_flif();
        return;

    case 0x0000004C: {
        struct ShellLinkHeader { align(1):
            //uint magic; // HeaderSize
            ubyte[16] clsid; /// Class identifier. MUST be 00021401-0000-0000-C000-000000000046.
            uint flags; /// Link attributes
            uint attrs; /// File attributes
            ulong creation_time;
            ulong access_time;
            ulong write_time;
            uint filesize;
            uint icon_index;
            uint show_command;
            ushort hotkey;
            ushort res1;
            uint res2, res3;
        }
        enum SW_SHOWNORMAL = 1, SW_SHOWMAXIMIZED = 3, SW_SHOWMINNOACTIVE = 7;
        /*enum SW_A = 1, /// HasLinkTargetIDList
             SW_B = 1 << 1, /// HasLinkInfo
             SW_F = 1 << 5, /// HasArguments
             SW_H = 1 << 7, /// IsUnicode
             SW_Z = 1 << 24; /// PreferEnvironmentPath*/

        ShellLinkHeader h;
        scpy(&h, h.sizeof);
        report("Microsoft Shortcut link (.LNK, MS-SHLLINK)", false);

        //TODO: Finish MS-SHLLINK

        with (h) {
            if (show_command)
            switch (show_command) {
                case SW_SHOWNORMAL: printf(", Normal window"); break;
                case SW_SHOWMAXIMIZED: printf(", Maximized"); break;
                case SW_SHOWMINNOACTIVE: printf(", Minimized"); break;
                default:
            }

            if (hotkey) {
                printf(", Hotkey (");
                const int high = hotkey & 0xFF00;
                if (high) {
                    if (high & 0x0100)
                        printf("shift+");
                    if (high & 0x0200)
                        printf("ctrl+");
                    if (high & 0x0400)
                        printf("alt+");
                }
                const int low = hotkey & 0xFF;
                if (low) {
                    if (low >= 0x30 && low <= 0x5A)
                        printf("%c", low);
                    else if (low >= 0x70 && low <= 0x87)
                        printf("F%d", low - 0x6F);
                    else switch (low) {
                        case 0x90: printf("num lock"); break;
                        case 0x91: printf("scroll lock"); break;
                        default:
                    }
                }
                printf(")");
            }

            /*if (flags & SW_A && flags & SW_B) {
                writeln;
                ushort l;
                fread(&l, 2, 1, fp);
                fseek(fp, l, SEEK_CUR);
                struct LinkInfo {}
            }*/

            writeln;

            if (More) {
                printf("LinkCLSID: ");
                print_array(&h.clsid, h.clsid.sizeof);
                printf("LinkFlags: %Xh\n", flags);
                printf("FileAttributes: %Xh\n", attrs);
                printf("CreationTime: %Xh\n", creation_time);
                printf("AccessTime: %Xh\n", access_time);
                printf("WriteTime: %Xh\n", write_time);
                printf("FileSize: %Xh\n", filesize);
                printf("IconIndex: %Xh\n", icon_index);
                printf("ShowCommand: %Xh\n", show_command);
                printf("HotKey: %Xh\n", hotkey);
            }
        }
    }
        return;

    case PST_MAGIC: // "!BDN"
        scan_pst;
        return;

    case 0x00000F01:
        report("MS-SQL database");
        return;

    default:
        switch (s & 0xFF_FFFF) {
            case 0x464947: // "GIF"
                scan_gif();
                break;

            case 0x685A42: // "BZh"
                report("Bzip2 compressed file (bzip2)");
                return;

            case 0xBFBBEF:
                report("UTF-8 text file with BOM");
                return;

            case 0x324449: // "ID3"
                report("MPEG-2 Audio Layer III audio file with ID3v2 (MP3)");
                return;

            case 0x53454E: // "NES"
                report("Nintendo Entertainment System ROM file (nes)");
                return;

            case 0x0184CF:
                report("Lepton compressed JPEG image (lep)");
                return;

            case 0x010100:
                report("OpenFlight 3D file");
                return;

        default:
            switch (s & 0xFFFF) {
            case 0x9D1F:
                report("Lempel-Ziv-Welch compressed archive (RAR/ZIP)");
                return;

            case 0xA01F:
                report("LZH compressed archive (RAR/ZIP)");
                return;

            case 0x5A4D: // "MZ"
                scan_mz();
                return;

            case 0xFEFF:
                report("UTF-16 text file (Byte-Order mark)");
                return;

            case 0xFBFF:
                report("MPEG-2 Audio Layer III audio file (MP3)");
                return;

            case 0x4D42:
                report("Bitmap image file (BMP)");
                return;

            case 0x8B1F:
                report("GZIP compressed file (gz)");
                return;

            case 0x8230:
                report("DER encoded X.509 certificate (der)");
                return;

            default:
                scan_etc;
                return;
            } // 2 Byte signatures
        } // 3 Byte signatures
    } // 4 Byte signatures
} // main

/// Report an unknown file type.
void report_unknown()
{
    if (ShowName)
        write(filename, ": ");
    writeln("Unknown type");
}

/// Report a text file.
// A few functions relies on this.
void report_text()
{
    report("Text file");
}

version (Windows) {
    version (Symlink) {
    /**
    * Some Microsoft thing used for DeviceIoCtl.
    * Params:
    *   t = Device type
    *   f = Function
    *   m = Method
    *   a = Access
    * Returns: BOOL
    */
    BOOL CTL_CODE(uint d, uint f, uint m, uint a) {
        return ((d) << 16) | ((a) << 14) | ((f) << 2) | (m);
    }
    import core.sys.windows.windows;
    enum FILE_ANY_ACCESS = 0; /// Any access to files.
    enum METHOD_BUFFERED = 0; /// Buffered access.
    enum FILE_DEVICE_FILE_SYSTEM = 0x00000009; /// File system access.
    enum FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000; /// Reparse point (symlink).
    enum FILE_FLAG_BACKUP_SEMANTICS   = 0x02000000; /// Backup semantics.
    /// FSCTL request, get reparse point
    enum FSCTL_GET_REPARSE_POINT = CTL_CODE(
            FILE_DEVICE_FILE_SYSTEM, 42, METHOD_BUFFERED, FILE_ANY_ACCESS
        );
    /// Symlink struct.
    struct WIN32_SYMLINK_REPARSE_DATA_BUFFER {
        DWORD             ReparseTag; /// Tag
        DWORD             ReparseDataLength; /// Data length
        WORD              Dummy; /// Unused
        WORD              ReparseTargetLength; ///  Target length
        WORD              ReparseTargetMaximumLength; /// Target maximum length
        WORD              Dummy1; /// Unused
        WCHAR[MAX_PATH]   ReparseTarget; /// Target path.
    }
    } // version (Symlink)
} // version (Windows)

/// Report a symbolic link.
void report_link()
{
    report("Soft symbolic link");

    version (Windows)
    { // Works half the time, see the Wiki post.
    version (Symlink)
    {
        HANDLE hFile;
        DWORD returnedLength;
        WIN32_SYMLINK_REPARSE_DATA_BUFFER buffer;

        const char* p = &linkname[0];
        SECURITY_ATTRIBUTES* sa; // Default

        hFile = CreateFileA(p, GENERIC_READ, 0u,
            sa, OPEN_EXISTING,
            FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, cast(void*)0);
        if (hFile == INVALID_HANDLE_VALUE) { //TODO: Check why LDC2 fails here.
            /* Error creating directory */
            /* TclWinConvertError(GetLastError()); */
            return;
        }
        /* Get the link */
        if (!DeviceIoControl(hFile, FSCTL_GET_REPARSE_POINT, NULL, 0, &buffer,
                WIN32_SYMLINK_REPARSE_DATA_BUFFER.sizeof, &returnedLength, NULL)) {
                /* Error setting junction */
                /* TclWinConvertError(GetLastError()); */
                CloseHandle(hFile);
                return;
            }

        CloseHandle(hFile);

        if (!IsReparseTagValid(buffer.ReparseTag)) {
            /* Tcl_SetErrno(EINVAL); */
            return;
        }

        DWORD wstrlen(const(void)* p) {
            DWORD s;
            wchar* wp = cast(wchar*)p;
            while (*wp++ != wchar.init) ++s;
            return s;
        }

        printf(" to ");
        stdout.flush; // on x86-dmd builds, used to move cursor
        const(void)* wp = &buffer.ReparseTarget[2];
        DWORD c;
        WriteConsoleW(
            GetStdHandle(STD_OUTPUT_HANDLE),
            wp,
            wstrlen(wp) / 2,
            &c,
            cast(void*)0
        );
    } // version (Symlink)
    } // version (Windows)
    version (Posix)
    {
        import core.stdc.stdio : printf;
        import core.sys.posix.stdlib : realpath;
        char* p = realpath(&linkname[0], cast(char*)0);
        if (p) printf(" to %s", p);
    }
}

/**
 * Report to stdout.
 * Params:
 *   type = File type
 *   nl = Print newline (default=true)
 */
void report(string type, bool nl = true)
{
    if (ShowName)
        writef("%s: ", filename);
    printf("%s", &type[0]);
    if (nl) writeln;
}