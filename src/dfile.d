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
version (Windows) {
    import core.stdc.wchar_ : wprintf;
    __gshared wstring filename; /// Filename
} else {
    __gshared string filename; /// Filename
}

__gshared bool More, /// -m : More flag
     ShowName, /// -s : Show name flag
     Base10; /// -b : Base 10 flag
__gshared FILE* fp; /// Current file handle.

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
        printf("LD2000 Frame (LDS)");
        break;*/

    /*case [0xBE, 0xBA, 0xFE, 0xCA]: // Conflicts with Mach-O
        report("Palm Desktop Calendar Archive (DBA)");
        break;*/

    case 0x44420100:
        report("Palm Desktop To Do archive (DBA)");
        return;

    case 0x54440100:
        report("Palm Desktop Calendar archive (TDA)");
        return;

    case 0x00000100: {
        char[12] b;
        fread(&b, 12, 1, fp);
        switch (b[0..4]) {
        case "MSIS":
            report("Microsoft Money");
            return;
        case "Stan":
            switch (b[8..12]) {
            case " ACE":
                report("Microsoft Access 2007 database");
                return;
            case " Jet":
                report("Microsoft Access database");
                return;
            default:
                report_unknown();
                return;
            }
        default:
            if (b[0] == 0)
                report("TrueType font");
            else
                report("Palm Desktop data Dile (Access)");
            return;
        }
    }

    case 0x4D53454E: { // "NESM"
        ubyte b;
        fread(&b, 1, 1, fp);
        switch (b) {
        case 0x1A: {
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
            fread(&h, h.sizeof, 1, fp);

            if (h.flag & 0b10)
                report("Dual NTSC/PAL", false);
            else if (h.flag & 1)
                report("NSTC", false);
            else
                report("PAL", false);

            printf(" Nintendo Sound audio, %d songs, ", h.total_song);

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
                cast(char*)&h.song_artist,
                cast(char*)&h.song_name,
                cast(char*)&h.song_copyright);
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
                fread(&h, h.sizeof, 1, fp);

                report("SNES sound (SPC2) v", false);
                printf("%d.%d, %d of SPC entries\n", h.major, h.minor, h.number);
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
        report("Ventura Publisher/GEM VDI Image Format Bitmap");
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
        report("DVD Video Movie File or DVD (MPEG2)");
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

    case 0x0C000000: //TODO: Maybe get those "various" JPEG-2000 images
        report("Various JPEG-2000 image formats");
        return;

    case 0xD75F2A80: //TODO: Maybe do Kodak Cineon images
    // http://www.cineon.com/ff_draft.php
        report("Kodak Cineon image (DPX)");
        return;

    case 0x01434E52, 0x02434E52: // RNC\x01 or \x02
        report("Rob Northen Compressed archive v", false);
        final switch (s >>> 24) { // Very lazy
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

    case 0xFB475042: // "BPGû"
        scan_bpg;
        return;

    case 0xDBFFD8FF, 0xE0FFD8FF, 0xE1FFD8FF:
        report("Joint Photographic Experts Group image (JPEG)");
        return;

    case 0xCEA1A367:
        report("IMG archive");
        return;

    //case "GBLE", "GBLF", "GBLG", "GBLI", "GBLS", "GBLJ":
    case 0x454C4247, 0x464C4247, 0x474C4247, 0x494C4247, 0x534C4247, 0x4A4C4247:
        report("GTA Text (GTA2+), ", false);
        final switch (s) {
        case 0x454C4247: printf("English\n");  break; // 'E'
        case 0x464C4247: printf("French\n");   break; // 'F'
        case 0x474C4247: printf("German\n");   break; // 'G'
        case 0x494C4247: printf("Italian\n");  break; // 'I'
        case 0x534C4247: printf("Spanish\n");  break; // 'S'
        case 0x4A4C4247: printf("Japanese\n"); break; // 'J'
        }
        return;

    case 0x47585432: { // "2TXG"
        uint b;
        fread(&b, 4, 1, fp);
        report("GTA Text 2, ", false);
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
        fread(&h , h.sizeof, 1, fp);
        report("RPF ", false);
        if (h.encrypted)
            printf("encrypted ");
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
                report("ISO Base Media (MPEG-4) v1");
                return;
            case "qt  ":
                report("QuickTime movie");
                return;
            case "3gp5":
                report("MPEG-4 video (MP4)");
                return;
            case "mp42":
                report("MPEG-4/QuickTime video (MP4)");
                return;
            case "MSNV":
                report("MPEG-4 video (MP4)");
                return;
            case "M4A ":
                report("Apple Lossless audio (M4A)");
                return;
            default:
                switch (b[4..7]) {
                case "3gp":
                    report("3rd Generation Partnership Project multimedia (3GP)");
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
        case "ILBM": /*ILBM*/ report("IFF Interleaved Bitmap image"); return;
        case "8SVX": /*8SVX*/ report("IFF 8-Bit voice"); return;
        case "ACBM": /*ACBM*/ report("Amiga Contiguous image"); return;
        case "ANBM": /*ANBM*/ report("IFF Animated image"); return;
        case "ANIM": /*ANIM*/ report("IFF CEL animation"); return;
        case "FAXX": /*FAXX*/ report("IFF Facsimile image"); return;
        case "FTXT": /*FTXT*/ report("IFF Formatted text"); return;
        case "SMUS": /*SMUS*/ report("IFF Simple Musical Score"); return;
        case "CMUS": /*CMUS*/ report("IFF Musical Score"); return;
        case "YUVN": /*YUVN*/ report("IFF YUV image"); return;
        case "FANT": /*FANT*/ report("Amiga Fantavision video"); return;
        case "AIFF": /*AIFF*/ report("Audio Interchange File audio (AIFF)"); return;
        default: report_unknown(); return;
        }
    }

    case 0xB7010000:
        report("MPEG video");
        return;

    case 0x58444E49: // "INDX"
        report("AmiBack backup index");
        return;

    case 0x50495A4C: // "LZIP"
        report("LZIP archive");
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
        fread(&h, h.sizeof, 1, fp);

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
            ubyte* filep = &file[0];
            fread(filep, h.fnlength, 1, fp);
            printf("%s, ", filep);
        }

        write(formatsize(h.csize), "/", formatsize(h.usize));

        enum {
            ENCRYPTED = 1, // 1
            ENHANCED_DEFLATION = 16, // 4
            COMPRESSED_PATCH = 32, // 5, data
            STRONG_ENCRYPTION = 64, // 6
        }

        if (h.flag & ENCRYPTED)
            printf(", encrypted");

        if (h.flag & STRONG_ENCRYPTION)
            printf(", strong encryption");

        if (h.flag & COMPRESSED_PATCH)
            printf(", compression patch");

        if (h.flag & ENHANCED_DEFLATION)
            printf(", enhanced deflation");

        printf("\n");

        if (More) {
            printf("Version    : %X\n", h.version_);
            printf("Flag       : %X\n", h.flag);
            printf("Compression: %X\n", h.compression);
            printf("Time       : %X\n", h.time);
            printf("Date       : %X\n", h.date);
            printf("CRC32      : %X\n", h.crc32);
            printf("Size (Uncompressed): %d\n", h.usize);
            printf("Size (Compressed)  : %d\n", h.csize);
            printf("Filename Size      : %d\n", h.fnlength);
            printf("Extra field Size   : %d\n", h.eflength);
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
        case x"1A 07 00":
            report("RAR archive v1.5+");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case 0x464C457F: // "\x7FELF"
        scan_elf;
        return;

    case 0x010E70FA: // FatELF
        scan_fatelf;
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
            report("Advanced Systems audio (ASF, WMA, WMV)");
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
            report("Microsoft System Deployment disk");
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
        fread(&h, h.sizeof, 1, fp);
        report("Ogg audio v", false);
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
        fread(&h, h.sizeof, 1, fp);
        report("FLAC audio", false);
        if ((h.header & 0xFF) == 0) { // Big endian. Not a fan.
            const int bits = ((h.stupid[8] & 1) << 4 | (h.stupid[9] >>> 4)) + 1;
            const int chan = ((h.stupid[8] >>> 1) & 7) + 1;
            const int rate =
                ((h.stupid[6] << 12) | h.stupid[7] << 4 | h.stupid[8] >>> 4);
            printf(", %d Hz, %d-bit, %d channels\n", rate, bits, chan);
            if (More) {
                printf("MD5: ");
                print_array(&h.md5, h.md5.length);
                printf("\n");
            }
        }
        else
            printf("\n");
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
        fread(&h, h.sizeof, 1, fp);
        report("Photoshop image v", false);
        printf("%d, %d x %d, %d-bit ",
            bswap16(h.version_), bswap32(h.width),
            bswap32(h.height), bswap16(h.depth));
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
        printf(", %d channel(s)\n", bswap16(h.channels));
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
                /*ushort extensionsize;
                ushort nbvalidbits;
                uint speakmask;*/ // Speaker position mask
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
            fread(&h, h.sizeof, 1, fp);
            report("WAVE audio (", false);
            switch (h.format) {
                case PCM: printf("PCM"); break;
                case IEEE_FLOAT: printf("IEEE Float"); break;
                case ALAW: printf("8-bit ITU G.711 A-law"); break;
                case MULAW: printf("8-bit ITU G.711 u-law"); break;
                case EXTENSIBLE: printf("EXTENDED"); break;
                case _MP2: printf("MPEG-1 Audio Layer II"); break;
                default: printf("Unknown type)\n"); return; // Ends here pal
            }
            printf(") %d Hz, %d kbps, %d-bit, ",
                h.samplerate, h.datarate / 1024 * 8, h.samplebits);
            switch (h.channels) {
                case 1: printf("Mono\n"); break;
                case 2: printf("Stereo\n"); break;
                default: printf("%d channels\n", h.channels); break;
            }
            if (More) {
                char[16] guid;
                fseek(fp, 8, SEEK_CUR);
                fread(&guid, guid.sizeof, 1, fp);
                printf("EXTENDED:");
                print_array(&guid, guid.length);
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
            report("Flexible Image Transport System image (FITS)");
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
        fread(&h, h.sizeof, 1, fp);

        report("MIDI: ", false);

        switch (bswap16(h.format)) {
        case 0: printf("Single track"); break;
        case 1: printf("Multiple tracks"); break;
        case 2: printf("Multiple songs"); break;
        default: printf("Unknown format"); return;
        }

        const ushort div = bswap16(h.division);
        printf(", %d tracks at ", bswap16(h.number));
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
        fread(&h, h.sizeof, 1, fp);
        report("Compound File Binary document v", false);
        printf("%d.%d, %d FAT sectors\n", h.major, h.minor, h.fat_sectors);
        if (More) {
            printf("%d directory sectors at %Xh\n",
                h.dir_sectors, h.first_dir_sector);
            if (h.trans_sig)
                printf("transaction signature, %Xh", h.trans_sig);
            printf("%d DIFAT sectors at %Xh\n",
                h.difat_sectors, h.first_difat_loc);
            printf("%d mini FAT sectors at %Xh\n",
                h.mini_fat_sectors, h.first_mini_fat_loc);
        }
        return;

    case 0x0A786564: // "dex\x0A", then follows "035\0"
        report("Dalvik executable");
        return;

    case 0x34327243: // "Cr24"
        report("Google Chrome extension or packaged app (CRX)");
        return;

    case 0x33444741: // "AGD3"
        report("FreeHand 8 document (FH8)");
        return;

    case 0x00000705: {
        char[6] b;
        fread(&b, 6, 1, fp);
        switch (b) {
        case [0x4F, 0x42, 0x4F, 0x05, 0x07, 0x00]:
            report("AppleWorks 5 document (CWK)");
            return;
        case [0x4F, 0x42, 0x4F, 0x06, 0x07, 0xE1]:
            report("AppleWorks 6 document (CWK)");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case 0x00025245: //TODO: Move this with those Apple DMG files?
        report("Roxio Toast disc or DMG (toast or dmg)");
        return;

    case 0x21726178: // "xar!"
        report("eXtensible archive (xar)");
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

    // Temporary out for being confusing
    /*case 0x33584F54: // "TOX3" 
        report("Open source portable voxel");
        return;*/

    case 0x49564C4D: // "MLVI"
        report("Magic Lantern video");
        return;

    case 0x004D4344: // "DCM\0", followed by "PA30"
        report("Windows Update Binary Delta Compression data");
        return;

    case 0xAFBC7A37: // Followed by [0x27, 0x1C]
        report("7-Zip archive (7z)");
        return;

    case 0x184D2204:
        report("LZ4 archive (lz4)");
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
        fread(&h, h.sizeof, 1, fp);
        report("Microsoft Cabinet archive v", false);
        printf("%d.%d, ", h.major, h.minor);
        write(formatsize(h.size));
        printf(", %d files, %d folders\n", h.files, h.folders);
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
        fread(&h, h.sizeof, 1, fp);
        report("InstallShield CAB archive", false);
        switch (h.version_) {
        case LEGACY:    printf(" (Legacy)");  break;
        case v2_20_905: printf(" v2.20.905"); break;
        case v3_00_065: printf(" v3.00.065"); break;
        case v5_00_000: printf(" v5.00.000"); break;
        default: printf(" (%08Xh)", h.version_); break;
        }
        printf(" at %Xh\n", h.desc_offset);
    }
        return;

    case 0xA3DF451A:
        report("Matroska video (mkv, webm)");
        return;

    case 0x204C494D: // "MIL "
        report(`"SEAN : Session Analysis" Training data`);
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
        report("WOFF 1.0 font (woff)");
        return;

    case 0x32464F77: // "wOF2"
        report("WOFF 2.0 font (woff)");
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
        rewind(fp);
        fread(&h, h.sizeof, 1, fp);
        if (h.file_iden != DEBIANBIN) {
            report_text(s);
            return;
        }
        report("Debian package v", false);
        writeln(h.version_);
        if (More) {
            deb_data_hdr dh;
            int os, dos;
            try {
                import std.conv : parse;
                string dps = isostr(h.ctl_filesize);
                os = parse!int(dps);
                fseek(fp, os, SEEK_CUR);
                fread(&dh, dh.sizeof, 1, fp);
                string doss = isostr(dh.filesize);
                dos = parse!int(doss);
            } catch (Exception) {
                return;
            }
            writef("%s - %s\n", isostr(h.ctl_file_ident), formatsize(os));
            writef("%s - %s\n", isostr(dh.file_ident), formatsize(dos));
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
        fread(&h, h.sizeof, 1, fp);
        report("RPM ", false);
        switch (h.type) {
            case 0: printf("binary"); break;
            case 0x100: printf("source"); break;
            default: printf("unknown"); break;
        }
        printf(" package v");
        printf(`%d.%d, "%s", `, h.major, h.minor, &h.name[0]);
        switch (h.osnum) {
            case 0x100: printf("linux"); break;
            default: printf("other"); break;
        }
        printf(" platforms\n");
    }
        return;

    case 0x44415749, 0x44415750: {// "IWAD", "PWAD"
        int[2] b; // Reads as ints.
        fread(&b, 8, 1, fp);
        report(s == 0x44415750 ? "PWAD" : "IWAD", false);
        printf(", %d entries at %Xh\n", b[0], b[1]);
        return;
    }

    case 0x6D736100: { // "\0asm", WebAssembly binary
        // http://webassembly.org/docs/binary-encoding/
        ubyte ver;
        fread(&ver, 1, 1, fp);
        report("WebAssembly v", false);
        printf("%d binary (wasm)\n", ver);
        return;
    }

    case 0x45555254: { // "TRUE"
        char[12] b;
        fread(&b, 12, 1, fp);
        switch (b) {
        case "VISION-XFILE":
            report("Truevision Targa Graphic image");
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
        rewind(fp);
        fread(&h, h.sizeof, 1, fp);

        report("MS-DOS ", false);

        switch (h.method) {
        case 0: printf("non-compressed"); break;
        case 1: printf("FFh-XOR'd data"); break;
        case 2: printf("regular SZDD compressed"); break;
        case 3: printf(`LZ + Huffman "Jeff Johnson" compressed`); break;
        case 4: printf("MS-ZIP compressed"); break;
        default: printf("unknown");
        }

        printf(" archive (KWAJ)");

        if (h.offset)
            printf(", offset: %Xh", h.offset);

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

            printf(`, "`);

            int c;

            if (name)
                while ((c = getc(fp)) != 0)
                    putchar(c);
            if (ext) {
                printf(".");
                while ((c = getc(fp)) != 0)
                    putchar(c);
            }

            printf(`"`);
        }

        printf("\n");
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
        rewind(fp);
        fread(&h, h.sizeof, 1, fp);

        report("MS-DOS SZDD ", false);

        if (h.compression != 'A')
            printf("(non-valid) ");

        printf("archive\n");
    }
        break;

    case 0x00020000:
        report("Lotus 1-2-3 spreadsheet (v1)");
        return;

    case 0x001A0000: {
        char[3] b;
        fread(&b, 3, 1, fp);
        switch (b) {
        case [0, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v3)");
            return;
        case [2, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v4, v5)");
            return;
        case [5, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v9)");
            return;
        default:
            report_unknown();
            return;
        }
    }

    case 0xF3030000:
        report("Amiga Hunk executable");
        return;    

    case 0x49490000, 0x4D4D0000: // "\0\0II", "\0\0MM"
        report("Quark Express document");
        return;

    case 0x0000FEFF:
        report("UTF-32, BOM (LSB)");
        return;
    case 0xFFFE0000:
        report("UTF-32, BOM (MSB)");
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
        fread(&h, h.sizeof, 1, fp);

        if (h.version_ == 1 || h.version_ == 2) {
            report("TRX v", false);
            printf("%d firmware (length: %d, CRC32: %Xh)\n",
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
        fread(&h, h.sizeof, 1, fp);

        report("VMware disk v", false);
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

        printf("\n");

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
        fread(&h, h.sizeof, 1, fp);
        if (h.flags != 3) {
            report_text(s);
            return;
        }
        const long size = h.numSectors * 512;
        report("ESXi COW disk v", false);
        string cows = formatsize(size);
        printf("%d, %s, \"%s\"\n",
            h.version_, &cows[0], &h.name[0]);

        if (More) {
            printf("Cylinders: %d\n", h.root.cylinders);
            printf("Heads: %d\n", h.root.heads);
            printf("Sectors: %d\n", h.root.sectors);
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
            report_text(s);
            return;
        }
        vhd_hdr h;
        fread(&h, h.sizeof, 1, fp);
        h.features = bswap32(h.features);
        if ((h.features & F_RES) == 0) {
            report_text(s);
            return;
        }
        report("Microsoft VHD disk v", false);
        printf("%d.%d, ", bswap16(h.major), bswap16(h.minor));

        h.disk_type = bswap32(h.disk_type);
        switch(h.disk_type) {
            case D_FIXED: printf("fixed"); break;
            case D_DYNAMIC: printf("dynamic"); break;
            case D_DIFF: printf("differencing"); break;
            default:
                if (h.disk_type < 7)
                    printf("reserved (deprecated)");
                else {
                    printf("Invalid type");
                    return;
                }
                break;
        }

        printf(", %s v%d.%d on ",
            &h.creator_app[0], bswap16(h.creator_major), bswap16(h.creator_minor));

        switch (h.creator_os) {
            case OS_WINDOWS: printf("Windows"); break;
            case OS_MAC:     printf("macOS"); break;
            default: printf("Unknown OS"); break;
        }

        write(", ", formatsize(bswap64(h.size_current)), "/",
            formatsize(bswap64(h.size_original)), " used",);

        if (h.features & F_TEMPORARY)
            printf(", temporary");

        if (h.savedState)
            printf(", saved state");

        printf("\n");

        if (More) {
            printf("UUID: ");
            print_array(&h.uuid, h.uuid.length);
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
        struct vdi_hdr { align(1): // Excludes char[64]
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
        fseek(fp, 64, SEEK_SET); // Skip description, char[64]
        vdi_hdr h;
        fread(&h, h.sizeof, 1, fp);
        if (h.magic != VDIMAGIC) {
            report_text(s); // Coincidence
            return;
        }
        report("VirtualBox VDI disk v", false);
        printf("%d.%d, ", h.majorv, h.minorv);
        VDIHEADER1 sh;
        switch (h.majorv) { // Use latest major version natively
            case 1:
                fread(&sh, sh.sizeof, 1, fp);
                break;
            case 0: { // Or else, translate
                VDIHEADER0 vd0;
                fread(&vd0, vd0.sizeof, 1, fp);
                with (vd0) {
                    sh.cbDisk = cbDisk;
                    sh.u32Type = u32Type;
                    sh.uuidCreate = uuidCreate;
                    sh.uuidModify = uuidModify;
                    sh.uuidLinkage = uuidLinkage;
                    sh.LegacyGeometry = LegacyGeometry;
                }
            }
                break;
            default: return;
        }
        switch (sh.u32Type) {
            case 1: printf("dynamic"); break;
            case 2: printf("static"); break;
            default: printf("unknown type"); break;
        }
        writeln(", ", formatsize(sh.cbDisk), " capacity");
        if (More) {
            printf("Create UUID : ");
            print_array(&sh.uuidCreate, 16);
            printf("Modify UUID : ");
            print_array(&sh.uuidModify, 16);
            printf("Link UUID   : ");
            print_array(&sh.uuidLinkage, 16);
            if (h.majorv >= 1) {
                printf("ParentModify UUID: ");
                print_array(&sh.uuidParentModify, 16);
                printf("Header size: ", sh.cbHeader);
            }
            printf("Cylinders (Legacy): %d\n", sh.LegacyGeometry.cCylinders);
            printf("Heads (Legacy): %d\n", sh.LegacyGeometry.cHeads);
            printf("Sectors (Legacy): %d\n", sh.LegacyGeometry.cSectors);
            printf("Sector size (Legacy): %d\n", sh.LegacyGeometry.cbSector);
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
        fread(&h, h.sizeof, 1, fp);

        report("QEMU QCOW2 disk v", false);
        write(bswap32(h.version_), ", ", formatsize(bswap64(h.size)), " capacity");

        switch (bswap32(h.crypt_method)) {
            case C_AES: printf(", AES encrypted"); break;
            default: break;
        }

        printf("\n");

        if (More) {
            printf("Number of snapshots: %d\n", bswap32(h.nb_snapshots));
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
        report("QEMU QED disk, ", false);
        qed_hdr h;
        fread(&h, h.sizeof, 1, fp);
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

        printf("\n");
    }
        return;

    case 0x0D730178, 0x6d697368: // Apple DMG disk image
        report("Apple disk (dmg)");
        return;

    case 0x6B6F6C79: { // "koly", Apple DMG disk image, big endian
//TODO: Continue Apple DMG
//https://www.virtualbox.org/browser/vbox/trunk/src/VBox/Storage/DMG.cpp
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
        fread(&h, h.sizeof, 1, fp);*/
        report("Apple disk (dmg)");
    }
        return;

    /*case 0x6d697368: // "mish", Apple DMG disk image

        return;*/

    //TODO: Parallels HDD (Lacks samples/documentation)
    /*case "With": { // WithoutFreeSpace -- Parallels HDD
        char[12]
        report("Parallels HDD disk image");
        return;
    }*/

    case 0x20584D50: // "PMX "
        scan_pmx;
        return;

    case 0x46494C46: // "FLIF"
        scan_flif;
        return;

    case 0x0000004C: { // See [MS-SHLLINK].pdf from Microsoft.
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
        enum SW_A = 1, /// HasLinkTargetIDList
             SW_B = 1 << 1; /// HasLinkInfo
             /*SW_F = 1 << 5, /// HasArguments
             SW_H = 1 << 7, /// IsUnicode
             SW_Z = 1 << 24; /// PreferEnvironmentPath*/

        ShellLinkHeader h;
        fread(&h, h.sizeof, 1, fp);
        report("Microsoft Shortcut link (MS-SHLLINK)", false);

        with (h) {
            if (show_command)
            switch (show_command) {
                case SW_SHOWNORMAL: printf(", normal window"); break;
                case SW_SHOWMAXIMIZED: printf(", maximized"); break;
                case SW_SHOWMINNOACTIVE: printf(", minimized"); break;
                default:
            }

            if (hotkey) {
                printf(", hotkey (");
                const int high = hotkey & 0xFF00;
                if (high) {
                    if (high & 0x0100)
                        printf("shift+");
                    if (high & 0x0200)
                        printf("ctrl+");
                    if (high & 0x0400)
                        printf("alt+");
                }
                const ubyte low = cast(ubyte)hotkey;
                if (low) {
                    if (low >= 0x30 && low <= 0x5A)
                        printf("%c", low);
                    else if (low >= 0x70 && low <= 0x87)
                        printf("F%d", low - 0x6F); // Function keys
                    else switch (low) {
                        case 0x90: printf("num lock"); break;
                        case 0x91: printf("scroll lock"); break;
                        default:
                    }
                }
                printf(")");
            }

            if (flags & SW_A && flags & SW_B) {
                ushort l;
                fread(&l, 2, 1, fp); // Read IDListSize
                fseek(fp, l + 47, SEEK_CUR); // Skip LinkTargetIDList to LinkInfo->LocalBasePath
                char[255] t;
                fread(&t, 255, 1, fp);
                printf(", to %s", &t[0]);
            }

            printf("\n");

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
        // Header is 96 bytes
        /*
            POSSIBLE STRUCTURE:
            u32 magic
            u32 RedoStartLSN
            u32 BindingId
            u32 SectorSize
            u32 Status
            u32 Growth
            // ...
        */
        return;

    default:
        switch (s & 0xFF_FFFF) {
        case 0x464947: // "GIF"
            scan_gif;
            break;

        case 0x685A42: // "BZh"
            report("Bzip2 archive (BZIP2)");
            return;

        case 0xBFBBEF:
            report("UTF-8 text, BOM");
            return;

        case 0x324449: // "ID3"
            report("MPEG-2 Audio Layer III audio (MP3), ID3v2");
            return;

        case 0x53454E: // "NES"
            report("Nintendo Entertainment System ROM (NES)");
            return;

        case 0x0184CF:
            report("Lepton-compressed JPEG image (LEP)");
            return;

        case 0x010100:
            report("OpenFlight 3D model");
            return;

        default:
            switch (cast(ushort)s) { // Uses MOVZX and avoids an AND instruction
            case 0x9D1F:
                report("Lempel-Ziv-Welch archive (RAR/ZIP)");
                return;

            case 0xA01F:
                report("LZH archive (RAR/ZIP)");
                return;

            case 0x5A4D: // "MZ"
                scan_mz;
                return;

            case 0xFEFF: //TODO: Check with UTF-32
                report("UTF-16 text file, BOM");
                return;

            case 0xFBFF:
                report("MPEG-2 Audio Layer III audio (MP3)");
                return;

            case 0x4D42:
                report("Bitmap image (BMP)");
                return;

            case 0x8B1F:
                report("GZIP archive (gz)");
                return;

            case 0x8230:
                report("DER X.509 certificate (der)");
                return;

            case 0x0908:
                report("Microsoft Excel BIFF8 spreadsheet");
                return;
            case 0x0904:
                report("Microsoft Excel BIFF4 spreadsheet");
                return;
            case 0x0902:
                report("Microsoft Excel BIFF3 spreadsheet");
                return;
            case 0x0900:
                report("Microsoft Excel BIFF2 spreadsheet");
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
        printf("%s: ", &filename[0]);
    printf("data\n");
}

/// Report a text file.
/// Params: s = Signature
void report_text(uint s)
{
    report("text");
}

version (Windows) {
    version (Symlink) { // define version in dub.sdl
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
    enum LINK = "Soft symbolic link";
    version (Windows)
    {
        version (Symlink) // Works half the time, see the Wiki post.
        {
            const wchar* p = &filename[0];
            SECURITY_ATTRIBUTES sa; // Default
            report(LINK, false);

            HANDLE hFile = CreateFileW(p, GENERIC_READ, 0u, &sa, OPEN_EXISTING,
                FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, cast(void*)0);
            if (hFile == INVALID_HANDLE_VALUE) { //TODO: Check why LDC2 fails here.
                /* Error creating directory */
                /* TclWinConvertError(GetLastError()); */
                debug printf("INVALID_HANDLE_VALUE");
                return;
            }

            DWORD returnedLength;
            WIN32_SYMLINK_REPARSE_DATA_BUFFER buffer;
            if (!DeviceIoControl(hFile, FSCTL_GET_REPARSE_POINT, NULL, 0, &buffer,
                    WIN32_SYMLINK_REPARSE_DATA_BUFFER.sizeof, &returnedLength, NULL)) {
                /* TclWinConvertError(GetLastError()); */
                debug printf("Error getting junction");
                CloseHandle(hFile);
                return;
            }

            CloseHandle(hFile);

            if (!IsReparseTagValid(buffer.ReparseTag)) {
                /* Tcl_SetErrno(EINVAL); */
                debug printf("Failed at IsReparseTagValid");
                return;
            }

            /*DWORD wstrlen(const(void)* p) {
                DWORD t;
                wchar* wp = cast(wchar*)p;
                while (*wp++ != wchar.init) ++s; // was against wchar.init
                return t;
            }*/

            //stdout.flush; // on x86-dmd builds, used to move cursor
            const(wchar)* wp = cast(wchar*)&buffer.ReparseTarget[2];
            DWORD c;
            printf(" to ");
            WriteConsoleA(
                GetStdHandle(STD_OUTPUT_HANDLE),
                wp,
                lstrlen(wp) / 2,
                &c,
                cast(void*)0
            );
        } else // version (Symlink)
            report(LINK);
    } // version (Windows)
    version (Posix)
    {
        import core.sys.posix.stdlib : realpath;
        char* p = realpath(&filename[0], cast(char*)0);
        report(LINK, false);
        if (p) printf(" to %s", p);
        printf("\n");
    }
}

/**
 * Report to stdout.
 * Params:
 *   type = File type (must be constant)
 *   nl = Print newline (default=true)
 */
void report(string type, bool nl = true)
{
    version (Windows) {
        if (ShowName) {
            //wprintf("%s: ", &filename[0]); // Won't work :-(
            writef("%s: ", filename);
        }
    } else {
        if (ShowName)
            printf("%s: ", &filename[0]);
    }
    printf("%s", &type[0]);
    if (nl) printf("\n");
}