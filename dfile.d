module dfile;

import std.stdio : write, writeln, writef, writefln, File;
import std.file : exists, isDir;
import s_elf : scan_elf;
import s_fatelf : scan_fatelf;
import s_mz : scan_mz;
import s_pe : scan_pe;
import s_ne : scan_ne;
import s_le : scan_le;
import s_mach : scan_mach;

const string PROJECT_NAME = "dfile";
const string PROJECT_VERSION = "0.1.0-dev";

static bool _debug, _more;

static File current_file;

//TODO: Use sliced buffer instead in case of EOF/garbage.
//TODO: Universal read_struct function (read_struct(object*,size_t)).
//TODO: implment -more in all scanners.

/*
https://en.wikipedia.org/wiki/List_of_file_signatures (Complete)
https://mimesniff.spec.whatwg.org
http://www.garykessler.net/library/file_sigs.html (To complete with)
Thought be warned with the last link, since there are entries that I do not
trust, and some entries repeat.
*/

static int main(string[] args)
{
    size_t l = args.length;
    
    if (l <= 1)
    {
        print_help;
        return 0;
    }

    string filename = args[l - 1]; // Last argument, no exceptions!

    for (int i = 0; i < l; ++i)
    {
        switch (args[i])
        {
        case "-d":
        case "--debug":
            _debug = true;
            writeln("Debugging mode turned on");
            break;

        case "-m":
        case "--more":
            _more = true;
            break;

        case "-h":
            print_help;
            return 0;

        case "--help":
            print_help_full;
            return 0;

        case "-v":
        case "--version":
            print_version;
            return 0;

        default:
        }
    }

    if (exists(filename))
    {
        if (isDir(filename))
        {
            writefln("%s: Directory", filename);
        }
        else
        {
            if (_debug)
                writefln("L%04d: Opening file..", __LINE__);
            current_file = File(filename, "rb");
            
            if (_debug)
                writefln("L%04d: Scaning file..", __LINE__);
            scan_file(current_file);
            
            if (_debug)
                writefln("L%04d: Closing file..", __LINE__);
            current_file.close();
        }
    }
    else
    {
        writefln("File does not exist: %s", filename);
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
    writeln("  -m, --more     Print more information (todo)");
    writeln("  -d, --debug    Print debugging information\n");
    writeln("  -h, --help        Print help and exit");
    writeln("  -v, --version     Print version and exit");;
}

static void print_version()
{
    writefln("%s - v%s", PROJECT_NAME, PROJECT_VERSION);
    writeln("Copyright (c) 2016 dd86k");
    writeln("License: MIT");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    writefln("Compiled on %s with %s v%s",
        __TIMESTAMP__, __VENDOR__, __VERSION__);
}

static void scan_file(File file)
{
    if (file.size == 0)
    {
        report("Empty file");
        return;
    }

    ubyte[4] magic;
    if (_debug)
        writefln("L%04d: Reading file..", __LINE__);
    file.rawRead(magic);
    
    if (_debug)
    {
        writef("L%04d: Magic - ", __LINE__);
        foreach (b; magic)
            writef("%X ", b);
        writeln();
    }

    const string sig = cast(string)magic;

    switch (sig)
    {
    // Conflicts with Mach-O, need more data for these files
    /*case [0xBE, 0xBA, 0xFE, 0xCA]:
        report("Palm Desktop Calendar Archive (DBA)");
        break;*/

    case [0x00, 0x01, 0x42, 0x44]:
        report("Palm Desktop To Do Archive (DBA)");
        break;

    case [0x00, 0x01, 0x44, 0x54]:
        report("Palm Desktop Calendar Archive (TDA)");
        break;

    case [0x00, 0x01, 0x00, 0x00]:
        {
            ubyte[12] b;
            file.rawRead(b);
            const string s = cast(string)b;
            switch (s[0..3])
            {
                case "MSIS":
                    report("Microsoft Money file");
                    break;
                case "Stan":
                    switch (s[8..11])
                    {
                        case " ACE":
                            report("Microsoft Access 2007 file");
                            break;
                        case " Jet":
                            report("Microsoft Access file");
                            break;
                        default:
                    }
                    break;
                default:
                    {
                        if (b[0] == 0)
                            report("TrueType font file");
                        else
                            report_unknown();
                    }
                    break;
            }    
        }
        report("Palm Desktop Data File (Access format)");
        break;

    case [0x00, 0x00, 0x01, 0x00]:
        report("Icon, ICO format");
        break;

    case [0, 1, 0, 8]:
        report("Ventura Publisher/GEM VDI Image Format Bitmap file");
        break;

    case "BACK":
        {
            file.rawRead(magic);
            string s = cast(string)magic;

            switch (s)
            {
            case "MIKE":
            {
                file.rawRead(magic);
                s = cast(string)magic;

                switch (s)
                {
                    case "DISK":
                        report("AmiBack backup");
                        break;

                    default:
                        report_unknown();
                        break;
                }
            }
            break;

            default:
                report_unknown();
                break;
            }
        }
        break;

    case "GIF8":
        {
            ubyte[2] b;
            file.rawRead(b);

            const string s = cast(string)b;

            switch (s)
            {
            case "7a":
                report("GIF87a");
                break;
            case "9a":
                report("GIF89a");
                break;

            default:
            }
        }
        break;

    case [0, 0, 1, 0xBA]:
        report("DVD Video Movie File or DVD MPEG2");
        break;

    case ['M', 'M', 0x00, '*']:
        report("Tagged Image File Format image (TIFF)");
        break;

    case ['I', 'I', '*', 0x00]:
        {
            ubyte[6] b;
            file.rawRead(b);
            const string s = cast(string)b;

            switch (s)
            {
            case [0x10, 0, 0, 0, 'C', 'R']:
                report("Canon RAW Format Version 2 image (TIFF)");
                break;

            default:
                report("Tagged Image File Format image (TIFF)");
                break;
            }
        }
        break;

    case [0, 0, 0, 0xc]:
        report("Various JPEG-2000 image file formats");
        break;

    case [0x80, 0x2A, 0x5F, 0xD7]:
        report("Kodak Cineon image");
        break;

    case ['R', 'N', 'C', 0x01]:
    case ['R', 'N', 'C', 0x02]:
        report("Compressed file (Rob Northen Compression v" ~
            (sig[3] == '\x01' ? '1' : '2') ~ ")");
        break;

    case "SDPX":
    case "XPDS":
        report("SMPTE DPX image");
        break;

    case [0x76, 0x2F, 0x31, 0x01]:
        report("OpenEXR image");
        break;

    case "BPGû":
        report("Better Portable Graphics image (BPG)");
        break;

    case [0xFF, 0xD8, 0xFF, 0xDB]:
    case [0xFF, 0xD8, 0xFF, 0xE0]:
    case [0xFF, 0xD8, 0xFF, 0xE1]:
        report("Joint Photographic Experts Group image (JPEG)");
        break;

    case ['g', 0xA3, 0xA1, 0xCE]:
        report("IMG archive");
        break;

    case [0xA9, 0x4E, 0x2A, 0x52]: //TODO: Finish https://www.gtamodding.com/wiki/IMG_archive
        report("IMG unencrypted archive");
        break;

    case "GBLE":
    case "GBLF":
    case "GBLG":
    case "GBLI":
    case "GBLS":
    case "GBLJ":
        writef("%s: GTA Text (GTA2+) file in ", file.name);
        final switch (sig[3])
        {
        case 'E':
            write("English");
            break;
        case 'F':
            write("French");
            break;
        case 'G':
            write("German");
            break;
        case 'I':
            write("Italian");
            break;
        case 'S':
            write("Spanish");
            break;
        case 'J':
            write("Japanese");
            break;
        }
        write(" language");
        break;

    case "2TXG": {
        ubyte[4] b;
        file.rawRead(b);
        int e = b[0] | b[1] << 8 | b[2] << 16 | b[3] << 24; // Byte swapped
        writef("%s: GTA Text 2 file with %d", file.name, e);
    }
        break;

    case "RPF0":
    case "RPF2":
    case "RPF3":
    case "RPF4":
    case "RPF6":
    case "RPF7": {
        writef("%s: RPF", file.name);
        int[4] buf; // Table of Contents Size, Number of Entries, ?, Encryted
        file.rawRead(buf);
        if (buf[3])
            write(" encrypted");
        write(" archive v" ~ sig[3] ~ " (");
        final switch (sig[3])
        {
            case '0':
                write("Table Tennis");
                break;
            case '2':
                write("GTA IV");
                break;
            case '3':
                write("GTA IV:A&MC:LA");
                break;
            case '4':
                write("Max Payne 3");
                break;
            case '6':
                write("Red Dead Redemption");
                break;
            case '7':
                write("GTA V");
                break;
        }
        writefln(") with %d entries", buf[1]);
    }
    break;

    case [0, 0, 0, 0x14]:
    case [0, 0, 0, 0x18]:
    case [0, 0, 0, 0x1C]:
    case [0, 0, 0, 0x20]: {
        ubyte[8] b;
        file.rawRead(b);
        const string s = cast(string)b;
        switch (s[0..3])
        {
        case "ftyp":
            switch (s[4..7])
            {
            case "isom":
                report("ISO Base Media file (MPEG-4) v1");
                break;

            case "qt  ":
                report("QuickTime movie file");
                break;

            case "3gp5":
                report("MPEG-4 video files (MP4)");
                break;

            case "mp42":
                report("MPEG-4 video/QuickTime file (MP4)");
                break;

            case "MSNV":
                report("MPEG-4 video file (MP4)");
                break;

            case "M4A ":
                report("Apple Lossless Audio Codec file (M4A)");
                break;

            default:
                switch (s[4..6])
                {
                case "3gp":
                    report("3rd Generation Partnership Project multimedia file (3GP)");
                    break;
                default:
                    report_unknown();
                    break;
                }
                break;
            }
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case "FORM": {
        ubyte[4] b;
        file.seek(8);
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "ILBM":
            report("IFF Interleaved Bitmap Image");
            break;
        case "8SVX":
            report("IFF 8-Bit Sampled Voice");
            break;
        case "ACBM":
            report("Amiga Contiguous Bitmap");
            break;
        case "ANBM":
            report("IFF Animated Bitmap");
            break;
        case "ANIM":
            report("IFF CEL Animation");
            break;
        case "FAXX":
            report("IFF Facsimile Image");
            break;
        case "FTXT":
            report("IFF Formatted Text");
            break;
        case "SMUS":
            report("IFF Simple Musical Score");
            break;
        case "CMUS":
            report("IFF Musical Score");
            break;
        case "YUVN":
            report("IFF YUV Image");
            break;
        case "FANT":
            report("Amiga Fantavision Movie");
            break;
        case "AIFF":
            report("Audio Interchange File Format");
            break;
        default:
        }
    }
        break;

    case [0, 0, 1, 0xB7]:
        report("MPEG video file");
        break;

    case "INDX":
        report("AmiBack backup index file");
        break;

    case "LZIP":
        report("lzip compressed file");
        break;

    case ['P', 'K', 0x03, 0x04]:
    case ['P', 'K', 0x05, 0x06]:
    case ['P', 'K', 0x07, 0x08]:
        report("ZIP compressed file (or JAR, ODF, OOXML)");
        break;

    case "Rar!": {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;
        switch (s)
        {
        case [0x1A, 0x07, 0x01, 0x00]:
            report("RAR archive v5.0+");
            break;
        default:
            report("RAR archive v1.5+");
            break;
        }
    }
        break;

    case [0x7F, 'E', 'L', 'F']:
        scan_elf(file);
        break;

    case [0xFA, 0x70, 0x0E, 0x01]: // FatELF - 0x1F0E70FA
        scan_fatelf(file);
        break;

    case [0x89, 'P', 'N', 'G']: {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;
        switch (s)
        {
        case [0x0D, 0x0A, 0x1A, 0x0A]:
            report("Portable Network Graphics image (PNG)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;
    
    case [0xFE, 0xED, 0xFA, 0xCE]: // MH_MAGIC
    case [0xFE, 0xED, 0xFA, 0xCF]: // MH_MAGIC_64
    case [0xCE, 0xFA, 0xED, 0xFE]: // MH_CIGAM
    case [0xCF, 0xFA, 0xED, 0xFE]: // MH_CIGAM_64
    case [0xCA, 0xFE, 0xBA, 0xBE]: // FAT_MAGIC
    case [0xBE, 0xBA, 0xFE, 0xCA]: // FAT_CIGAM
        scan_mach(file);
        break;

    /*case [0xFE, 0xED, 0xFA, 0xCE]: // FEED FACE?
        report("Mach-O binary (32-bit)");
        break;
    case [0xFE, 0xED, 0xFA, 0xCF]:
        report("Mach-O binary (64-bit)");
        break;
    case [0xCE, 0xFA, 0xED, 0xFE]:
        report("Mach-O binary (32-bit, Reversed)");
        break;
    case [0xCF, 0xFA, 0xED, 0xFE]:
        report("Mach-O binary (64-bit, Reversed)");
        break;*/

    case [0xFF, 0xFE, 0x00, 0x00]:
        report("UTF-32 text file (byte-order mark)");
        break;

    case "%!PS":
        report("PostScript document");
        break;

    case "%PDF":
        report("PDF document");
        break;

    case [0x30, 0x26, 0xB2, 0x75]: {
        ubyte[12] b;
        file.rawRead(b);
        string s = cast(string)b;
        switch (s)
        {
        case [0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9, 0, 0xAA, 0, 0x62, 0xCE, 0x6C]:
            report("Advanced Systems Format file (ASF, WMA, WMV)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case "$SDI": {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case [0x30, 0x30, 0x30, 0x31]:
            report("System Deployment Image (Microsoft disk image)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case "OggS":
        report("Ogg audio file");
        break;

    case "8BPS":
        report("Photoshop native document file");
        break;

    case "RIFF": {
        ubyte[4] b;
        file.seek(8);
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "WAVE":
            report("Waveform Audio File (wav)");
            break;
        case "AVI ":
            report("Audio Video Interface video (avi)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    /*case "CD00": // Offset: 0x8001, 0x8801, 0x9001
        {
            ubyte[1] b;
            file.rawRead(b);
            string s = cast(string)b;

            switch (s)
            {
                case ['1']:
                    report("ISO9660 CD/DVD image file (ISO)");
                    break;
                default:
                    report_unknown(file);
                    break;
            }
        }
        break;*/

    case "SIMP": {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "LE  ":
            report("Flexible Image Transport System (FITS)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case "fLaC":
        report("Free Lossless Audio Codec audio file (FLAC)");
        break;

    case "MThd":
        report("MIDI file");
        break;

    case [0xD0, 0xCF, 0x11, 0xE0]: {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case [0xA1, 0xB1, 0x1A, 0xE1]:
            report("Compound File Binary Format document (doc, xls, ppt)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case ['d', 'e', 'x', 0x0A]: {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "035\0":
            report("Dalvik Executable");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case "Cr24":
        report("Google Chrome extension or packaged app (crx)");
        break;

    case "AGD3":
        report("FreeHand 8 document (fh8)");
        break;

    case [0x05, 0x07, 0x00, 0x00]: {
        ubyte[6] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case [0x4F, 0x42, 0x4F, 0x05, 0x07, 0x00]:
            report("AppleWorks 5 document (cwk)");
            break;
        case [0x4F, 0x42, 0x4F, 0x06, 0x07, 0xE1]:
            report("AppleWorks 6 document (cwk)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case ['E', 'R', 0x02, 0x00]:
        report("Roxio Toast disc image or DMG file (toast or dmg)");
        break;

    case ['x', 0x01, 's', 0x0D]:
        report("Apple Disk Image file (dmg)");
        break;

    case "xar!":
        report("eXtensible ARchive format (xar)");
        break;

    case "PMOC": {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "CMOC":
            report("USMT, Windows Files And Settings Transfer Repository (dat)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    /*case "usta": // Tar offset 0x101
        {

        }
        break;*/

    case "TOX3":
        report("Open source portable voxel file");
        break;

    case "MLVI":
        report("Magic Lantern Video file");
        break;

    case "DCM\0": {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "PA30":
            report("Windows Update Binary Delta Compression");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case [0x37, 0x7A, 0xBC, 0xAF]: {
        ubyte[2] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case [0x27, 0x1C]:
            report("7-Zip compressed file (7z)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case [0x04, 0x22, 0x4D, 0x18]:
        report("LZ4 Streaming Format (lz4)");
        break;

    case "MSCF":
        report("Microsoft Cabinet File (cab)");
        break;

    case "FLIF":
        report("Free Lossless Image Format image file (flif)");
        break;

    case [0x1A, 0x45, 0xDF, 0xA3]:
        report("Matroska media container (mkv, webm)");
        break;

    case "MIL ":
        report(`"SEAN : Session Analysis" Training file`);
        break;

    case "AT&T": {
        ubyte[4] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "FORM": {
            file.seek(8);
            file.rawRead(b);
            s = cast(string)b;

            switch (s)
            {
            case "DJVU":
                report("DjVu document, single page");
                break;
            case "DJVM":
                report("DjVu document, multiple pages");
                break;
            default:
                report_unknown();
                break;
            }
        }
        break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case "wOFF":
        report("WOFF File Format 1.0 font (woff)");
        break;
    case "wOF2":
        report("WOFF File Format 2.0 font (woff)");
        break;

    case "<?xm": {
        ubyte[2] b;
        file.rawRead(b);
        string s = cast(string)b;

        switch (s)
        {
        case "l>":
            report("ASCII XML (xml)");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break; // too lazy for utf-16/32

    case "PWAD":
    case "IWAD": {
        int[2] b; // Doom reads as int
        file.rawRead(b);
        writefln("%s: %s holding %d entries at %Xh", file.name, sig, b[0], b[1]);
    }
        break;

    case "\0asm":
        report("WebAssembly file (wasm)");
        break;

    case "TRUE": {
        ubyte[12] b;
        file.rawRead(b);

        switch (cast(string)b)
        {
        case "VISION-XFILE":
            report("Truevision Targa Graphic image file");
            break;
        default:
            report_unknown();
            break;
        }
    }
    break;

    case [0, 0, 2, 0]:
        report("Lotus 1-2-3 spreadsheet (v1) file");
        break;

    case [0, 0, 0x1A, 0]: {
        ubyte[3] b;
        file.rawRead(b);

        const string s = cast(string)b;

        switch (s)
        {
        case [0, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v3) file");
            break;
        case [2, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v4, v5) file");
            break;
        case [5, 0x10, 4]:
            report("Lotus 1-2-3 spreadsheet (v9) file");
            break;
        default:
            report_unknown();
            break;
        }
    }
        break;

    case [0, 0, 3, 0xF3]:
        report("Amiga Hunk executable file");
        break;    

    case "\0\0II":
    case "\0\0MM":
        report("Quark Express document");
        break;

    case [0, 0, 0xFE, 0xFF]:
        report("UTF-32BE file");
        break;

    default: {
        switch (sig[0..2])
        {
        case [0x1F, 0x9D]:
            report("Lempel-Ziv-Welch compressed file (RAR/ZIP)");
            break;

        case [0x1F, 0xA0]:
            report("LZH compressed file (RAR/ZIP)");
            break;

        case "MZ":
            scan_mz(file);
            break;

        case [0xFF, 0xFE]:
            report("UTF-16 text file (Byte-Order mark)");
            break;

        case [0xFF, 0xFB]:
            report("MPEG-2 Audio Layer III audio file (MP3)");
            break;

        case "BM":
            report("Bitmap iamge file (BMP)");
            break;

        case [0x1F, 0x8B]:
            report("GZIP compressed file ([tar.]gz)");
            break;

        case [0x30, 0x82]:
            report("DER encoded X.509 certificate (der)");
            break;

        default:
            switch (sig[0..3])
            {
            case "BZh":
                report("Bzip2 compressed file (BZh)");
                break;

            case [0xEF, 0xBB, 0xBF]:
                report("UTF-8 text file with BOM");
                break;

            case "ID3":
                report("MPEG-2 Audio Layer III audio file with ID3v2 container (MP3)");
                break;

            case "KDM":
                report("VMware Disk K virtual disk file (VMDK)");
                break;

            case "NES":
                report("Nintendo Entertainment System ROM file (nes)");
                break;

            case [0xCF, 0x84, 0x01]:
                report("Lepton compressed JPEG image (lep)");
                break;

            case [0, 1, 1]:
                report("OpenFlight 3D file");
                break;

            default:
                report_unknown();
                break;
            }
            break; // 3 Byte signatures
        }
    }
    break; // Signature
    }
}

static void report(string type)
{
    writefln("%s: %s", current_file.name, type);
}

static void report_unknown()
{
    writefln("%s: Unknown file format", current_file.name);
}

/+static void read_struct(File file, void* pstruct, size_t s_size, bool rewind)
{
    import core.stdc.string;
    if (rewind)
        file.rewind();
    if (_debug)
        writeln("read_struct s_size: ", s_size);
    ubyte[] buffer = new ubyte[s_size];
    if (_debug)
        writeln("read_struct size: ", buffer.length);
    buffer = file.rawRead(buffer);
    if (_debug)
        writeln("read_struct size: ", buffer.length);
    memcpy(pstruct, &buffer, buffer.length);
}+/

/*
 * Etc.
 */

const size_t BYTE_LIMIT = 1024 * 64;

/// __ETC
static void scan_unknown(File file)
{
    // Scan for readable characters for X(64KB?) bytes and at least
    // Y(3?) readable characters
    throw new Exception("TODO: scan_unknown");
}