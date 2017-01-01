import std.stdio : write, writeln, writef, writefln, File;
import std.file : exists, isDir;

const string PROJECT_NAME = "dfile";
const string PROJECT_VERSION = "0.1.0";

static bool _debug, _more;

static File current_file;

/*
https://en.wikipedia.org/wiki/List_of_file_signatures (Complete)
https://mimesniff.spec.whatwg.org
http://www.garykessler.net/library/file_sigs.html (To complete with)
*/

/*
 * Sections (That Search feature is going to be handy! __*)
 * 1. Generic (__GENERIC)
 *   a. TODO: Re-organize by category (audio, etc.)
 * 2. MZ, NE, LE, LX, PE32 (__PE32)
 * 3. ELF (__ELF)
 * 4. Misc. (__ETC)
 */

static int main(string[] args)
{
    size_t l = args.length;

    if (l <= 1)
    {
        print_help;
        return 0;
    }

    string filename = args[$-1];

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
    writeln("  -m, --more     Print more information");
    writeln("  -d, --debug    Print debugging information\n");
    writeln("  -h     Print help and exit");
    writeln("  -v,      Print version and exit");;
}

static void print_version()
{
    writefln("%s - v%s", PROJECT_NAME, PROJECT_VERSION);
    writeln("Copyright (c) 2016 dd86k");
    writeln("License: MIT");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    writefln("Compiled on %s with %s v%s", __TIMESTAMP__, __VENDOR__, __VERSION__);
}

/// __GENERIC
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
    case [0xBE, 0xBA, 0xFE, 0xCA]:
        report("Palm Desktop Calendar Archive (DBA)");
        break;

    case [0x00, 0x01, 0x42, 0x44]:
        report("Palm Desktop To Do Archive (DBA)");
        break;

    case [0x00, 0x01, 0x44, 0x54]:
        report("Palm Desktop Calendar Archive (TDA)");
        break;

    case [0x00, 0x01, 0x00, 0x00]:
        {
            char[12] b;
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
                }
            }
            break;

            default:
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
        report("Compressed file (Rob Northen Compression v1/v2)");
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

    case [0, 0, 0, 0x14]:
    case [0, 0, 0, 0x18]:
    case [0, 0, 0, 0x1C]:
    case [0, 0, 0, 0x20]:
        {
            char[8] b;
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

    case "FORM":
        {
            ubyte[4] b;
            file.seek(8, 0);
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

    case "Rar!":
        {
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

    case [0x89, 'P', 'N', 'G']:
        {
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

    case [0xCA, 0xFE, 0xBA, 0xBE]:
        report("Java class file, Mach-O Fat Binary");
        break;

    case [0xFE, 0xED, 0xFA, 0xCE]:
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
        break;

    case [0xFF, 0xFE, 0x00, 0x00]:
        report("UTF-32 text file (byte-order mark)");
        break;

    case "%!PS":
        report("PostScript document");
        break;

    case "%PDF":
        report("PDF document");
        break;

    case [0x30, 0x26, 0xB2, 0x75]:
        {
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

    case "$SDI":
        {
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

    case "RIFF":
        {
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

    case "SIMP":
        {
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

    case [0xD0, 0xCF, 0x11, 0xE0]:
        {
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

    case ['d', 'e', 'x', 0x0A]:
        {
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

    case [0x05, 0x07, 0x00, 0x00]:
        {
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

    case "PMOC":
        {
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

    case "DCM\0":
        {
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

    case [0x37, 0x7A, 0xBC, 0xAF, 0x27]:
        {
            ubyte[1] b;
            file.rawRead(b);
            string s = cast(string)b;

            switch (s)
            {
            case [0x1C]:
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

    case "AT&T":
        {
            char[4] b;
            file.rawRead(b);
            string s = cast(string)b;

            switch (b)
            {
            case "FORM":
                {
                    file.seek(4);
                    file.rawRead(b);
                    s = cast(string)b;

                    switch (s)
                    {
                        case "DJVU":
                            report("DjVu document, single page (djvu)");
                            break;
                        case "DJVM":
                            report("DjVu document, multiple pages (djvu)");
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

    case "<?xm":
        {
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
    case "IWAD":
    {
        int[2] b; // Doom reads as int
        file.rawRead(b);

        writefln("%s: %s holding %d entries at %Xh", file.name, sig, b[0], b[1]);
    }
    break;

    case "\0asm":
        report("WebAssembly file (wasm)");
        break;

    case "TRUE":
    {
        char[12] b;
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

    case [0, 0, 0x1A, 0]:
        {
            char[3] b;
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

    default:
        {
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
                break;
            }
        }
        break;
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

/**
 * MZ/NE/LE/LX/PE32 File Scanner | __PE32
 */

struct PE_HEADER
{
    char[4] Signature;
    PE_MACHINE_TYPE Machine;
    ushort NumberOfSections;
    uint TimeDateStamp;
    uint PointerToSymbolTable;
    uint NumberOfSymbols;
    ushort SizeOfOptionalHeader;
    PE_CHARACTERISTIC_TYPE Characteristics;
}

struct PE_OPTIONAL_HEADER
{
    PE_FORMAT Format;
    byte MajorLinkerVersion;
    byte MinorLinkerVersion;
    uint SizeOfCode;
    uint SizeOfInitializedData;
    uint SizeOfUninitializedData;
    uint AddressOfEntryPoint;
    uint BaseOfCode;
    union {
        uint BaseOfData;
        uint ImageBase; // ??
    }
    uint SectionAlignment;
    uint FileAlignment;
    ushort MajorOperatingSystemVersion;
    ushort MinorOperatingSystemVersion;
    ushort MajorImageVersion;
    ushort MinorImageVersion;
    ushort MajorSubsystemVersion;
    ushort MinorSubsystemVersion;
    uint Win32VersionValue;
    uint SizeOfImage;
    uint SizeOfHeaders;
    uint CheckSum;
    WIN_SUBSYSTEM Subsystem;
}

enum PE_MACHINE_TYPE : ushort
{
    IMAGE_FILE_MACHINE_UNKNOWN = 0x0,
    IMAGE_FILE_MACHINE_AM33 = 0x1d3,
    IMAGE_FILE_MACHINE_AMD64 = 0x8664,
    IMAGE_FILE_MACHINE_ARM = 0x1c0,
    IMAGE_FILE_MACHINE_ARMNT = 0x1c4,
    IMAGE_FILE_MACHINE_ARM64 = 0xaa64,
    IMAGE_FILE_MACHINE_EBC = 0xebc,
    IMAGE_FILE_MACHINE_I386 = 0x14c,
    IMAGE_FILE_MACHINE_IA64 = 0x200,
    IMAGE_FILE_MACHINE_M32R = 0x9041,
    IMAGE_FILE_MACHINE_MIPS16 = 0x266,
    IMAGE_FILE_MACHINE_MIPSFPU = 0x366,
    IMAGE_FILE_MACHINE_MIPSFPU16 = 0x466,
    IMAGE_FILE_MACHINE_POWERPC = 0x1f0,
    IMAGE_FILE_MACHINE_POWERPCFP = 0x1f1,
    IMAGE_FILE_MACHINE_R4000 = 0x166,
    IMAGE_FILE_MACHINE_SH3 = 0x1a2,
    IMAGE_FILE_MACHINE_SH3DSP = 0x1a3,
    IMAGE_FILE_MACHINE_SH4 = 0x1a6,
    IMAGE_FILE_MACHINE_SH5 = 0x1a8,
    IMAGE_FILE_MACHINE_THUMB = 0x1c2,
    IMAGE_FILE_MACHINE_WCEMIPSV2 = 0x169
}

enum PE_CHARACTERISTIC_TYPE : ushort
{
    IMAGE_FILE_RELOCS_STRIPPED = 0x0001,
    IMAGE_FILE_EXECUTABLE_IMAGE = 0x0002,
    IMAGE_FILE_LINE_NUMS_STRIPPED = 0x0004,
    IMAGE_FILE_LOCAL_SYMS_STRIPPED = 0x0008,
    IMAGE_FILE_AGGRESSIVE_WS_TRIM = 0x0010,
    IMAGE_FILE_LARGE_ADDRESS_AWARE = 0x0020,
    IMAGE_FILE_16BIT_MACHINE = 0x0040,
    IMAGE_FILE_BYTES_REVERSED_LO = 0x0080,
    IMAGE_FILE_32BIT_MACHINE = 0x0100,
    IMAGE_FILE_DEBUG_STRIPPED = 0x0200,
    IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP = 0x0400,
    IMAGE_FILE_SYSTEM = 0x1000,
    IMAGE_FILE_DLL = 0x2000,
    IMAGE_FILE_UP_SYSTEM_ONLY = 0x4000,
    IMAGE_FILE_BYTES_REVERSED_HI = 0x8000
}

enum PE_FORMAT
{
    ROM   = 0x0107,
    PE32  = 0x010B,
    PE32P = 0x020B
}

enum WIN_SUBSYSTEM : ushort
{
    IMAGE_SUBSYSTEM_UNKNOWN,
    IMAGE_SUBSYSTEM_NATIVE,
    IMAGE_SUBSYSTEM_WINDOWS_GUI,
    IMAGE_SUBSYSTEM_WINDOWS_CUI,
    IMAGE_SUBSYSTEM_POSIX_CUI,
    IMAGE_SUBSYSTEM_WINDOWS_CE_GUI,
    IMAGE_SUBSYSTEM_EFI_APPLICATION,
    IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER,
    IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER,
    IMAGE_SUBSYSTEM_EFI_ROM,
    IMAGE_SUBSYSTEM_XBOX,
}

struct LE_HEADER
{
    char[2] Signature; //"LX"
    ubyte ByteOrder;
    ubyte WordOrder;
    uint FormatLevel;
    ushort CPUType;
    ushort OSType;
    uint ModuleVersion;
    uint ModuleFlags;
    // And these are the most interesting parts.
}

struct NE_HEADER
{
    char[2] Signature;
    ubyte MajLinkerVersion;
    ubyte MinLinkerVersion;
    ushort EntryTableOffset;
    ushort EntryTableLength;
    uint FileLoadCRC;
    ubyte ProgFlags;
    ubyte ApplFlags;
    ubyte AutoDataSegIndex;
    ushort InitHeapSize;
    ushort InitStackSize;
    uint EntryPoint;
    uint InitStack;
    ushort SegCount;
    ushort ModRefs;
    ushort NoResNamesTabSiz;
    ushort SegTableOffset;
    ushort ResTableOffset;
    ushort ResidNamTable;
    ushort ModRefTable;
    ushort ImportNameTable;
    uint OffStartNonResTab;
    ushort MovEntryCount;
    ushort FileAlnSzShftCnt;
    ushort nResTabEntries;
    ubyte targOS;
}

static void scan_mz(File file)
{
    import core.stdc.string;
    //TODO: Use memcpy instead of manually playing with pointers.

    if (_debug)
        writefln("L%04d: Started scanning PE file", __LINE__);

    uint header_offset;
    {
        int[1] b;
        file.seek(0x3c, 0);
        file.rawRead(b);
        header_offset = b[0];

        if (_debug)
            writefln("L%04d: PE Header Offset: %X", __LINE__, header_offset);

        file.seek(header_offset, 0);
        char[2] pesig;
        file.rawRead(pesig);

        if (header_offset)
            switch (cast(string)pesig)
            {
            case "PE": break; // PE32 has the biggest analysis part

            case "NE":
            {
                NE_HEADER peh;
                {
                    file.seek(header_offset, 0);
                    ubyte[NE_HEADER.sizeof] buf;
                    file.rawRead(buf);
                    
                    ubyte* pbuf = cast(ubyte*)&buf, ppeh = cast(ubyte*)&peh;

                    for (size_t i = 0; i < NE_HEADER.sizeof; ++i)
                        *(ppeh + i) = *(pbuf + i);
                }

                writef("%s: NE ", file.name);

                if (peh.ApplFlags & 0x80)
                    write("DLL/Driver");
                else
                    write("Executable");

                write(" (");

                switch (peh.targOS)
                {
                    default: case 0:
                        write("Unknown");
                        break;
                    case 1:
                        write("OS/2");
                        break;
                    case 2:
                        write("Windows");
                        break;
                    case 3:
                        write("European MS-DOS 4.x");
                        break;
                    case 4:
                        write("Windows 386");
                        break;
                    case 5:
                        write("BOSS");
                        break;
                }

                write(") with ");
                
                if (peh.ProgFlags & 0x80)
                    write("80x87");
                else if (peh.ProgFlags & 0x40)
                    write("80386");
                else if (peh.ProgFlags & 0x20)
                    write("80286");
                else
                    write("8086");

                writeln(" instructions");
            }
            return;

            case "LE": case "LX": // LE/LX
            {
                LE_HEADER peh;
                {
                    file.seek(header_offset, 0);
                    ubyte[LE_HEADER.sizeof] buf;
                    file.rawRead(buf);
                    
                    ubyte* pbuf = cast(ubyte*)&buf, ppeh = cast(ubyte*)&peh;

                    for (size_t i = 0; i < LE_HEADER.sizeof; ++i)
                        *(ppeh + i) = *(pbuf + i);
                }

                writef("%s: %s ", file.name, pesig);

                if (peh.ModuleFlags & 0x8000)
                    write("Libary module");
                else
                    write("Program module");

                write(" (");

                switch (peh.OSType)
                {
                default: case 0:
                    write("Unknown");
                    break;
                case 1:
                    write("OS/2");
                    break;
                case 2:
                    write("Windows");
                    break;
                case 3:
                    write("DOS 4.x");
                    break;
                case 4:
                    write("Windows 386");
                    break;
                }

                write("), ");

                switch (peh.CPUType)
                {
                default:
                    write("unknown");
                    break;
                case 1:
                    write("Intel 80286");
                    break;
                case 2:
                    write("Intel 80386");
                    break;
                case 3:
                    write("Intel 80486");
                    break;
                }

                writeln(" CPU and up");
            }
            return;

            default:
                writefln("%s: MZ Executable (MS-DOS)", file.name);
                return;
            }
        else
            writefln("%s: MZ Executable (MS-DOS)", file.name);
    }

    PE_HEADER peh; // PE32
    PE_OPTIONAL_HEADER peoh;
    {
        file.seek(header_offset, 0);

        ubyte[PE_HEADER.sizeof] buf;
        file.rawRead(buf);
        
        ubyte* pbuf = cast(ubyte*)&buf, ppeh = cast(ubyte*)&peh;

        for (size_t i = 0; i < PE_HEADER.sizeof; ++i)
            *(ppeh + i) = *(pbuf + i);

        if (peh.SizeOfOptionalHeader > 0)
        { // PE Optional Header
            ubyte[PE_OPTIONAL_HEADER.sizeof] obuf;
            file.rawRead(obuf);
            
            ubyte* pobuf = cast(ubyte*)&obuf, ppeoh = cast(ubyte*)&peoh;

            for (size_t i = 0; i < PE_OPTIONAL_HEADER.sizeof; ++i)
                *(ppeoh + i) = *(pobuf + i);
            
            // ?????????????????????????????
            peoh.Format = cast(PE_FORMAT)(obuf[0] | (obuf[1] << 8));
        }

        /*if (_debug)
        {
            writef("L%04d: Buffer : ", __LINE__);
            foreach (i; b)
                writef("%04X ", i);
            writeln();
        }*/
    }

    if (_more || _debug)
    {
        writefln("Machine type : %s", peh.Machine);
        writefln("Number of sections : %s", peh.NumberOfSymbols);
        writefln("Time stamp : %s", peh.TimeDateStamp);
        writefln("Pointer to Symbol Table : %s", peh.PointerToSymbolTable);
        writefln("Number of symbols : %s", peh.NumberOfSymbols);
        writefln("Size of Optional Header : %s", peh.SizeOfOptionalHeader);
        writefln("Characteristics : %Xh", peh.Characteristics);

        if (peh.SizeOfOptionalHeader > 0)
        {
            writefln("Format : %Xh", peoh.Format);
            writefln("Subsystem : %Xh", peoh.Subsystem);
        }
    }
    
    writef("%s: PE32", file.name);
    
    switch (peoh.Format)
    {
    case PE_FORMAT.ROM:
        write("-ROM ");
        break;
    case PE_FORMAT.PE32:
        write(" ");
        break;
    case PE_FORMAT.PE32P:
        write("+ ");
        break;
    default:
        write(" (?) ");
        break;
    }

    switch (peoh.Subsystem)
    {
    default:
    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_UNKNOWN:
        write("(Unknown)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_NATIVE:
        write("(Native)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_WINDOWS_GUI:
        write("(GUI)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_WINDOWS_CUI:
        write("(CUI)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_POSIX_CUI:
        write("(POSIX CUI)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_WINDOWS_CE_GUI:
        write("(CE GUI)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_EFI_APPLICATION :
        write("(EFI)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER :
        write("(EFI Boot Service Driver)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER:
        write("(EFI Runtime driver)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_EFI_ROM:
        write("(EFI ROM)");
        break;

    case WIN_SUBSYSTEM.IMAGE_SUBSYSTEM_XBOX:
        write("(XBOX)");
        break;
    }

    write(" Windows ");

    if (peh.Characteristics & PE_CHARACTERISTIC_TYPE.IMAGE_FILE_DLL)
        write("Library (DLL)");
    else
        write("Executable (EXE)");

    write(" for ");

    switch (peh.Machine)
    {
    default:
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_UNKNOWN:
        write("Unknown");
        break;

    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_AM33:
        write("Matsushita AM33");
        break;

    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_AMD64:
        write("x86-64");
        break;

    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_ARM:
        write("ARM (Little endian)");
        break;

    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_ARMNT:
        write("ARMv7+ (Thumb mode)");
        break;

    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_ARM64:
        write("ARMv8 (64-bit)");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_EBC:
        write("EFI (Byte Code)");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_I386:
        write("x86");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_IA64:
        write("IA64");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_M32R:
        write("Mitsubishi M32R (Little endian)");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_MIPS16:
        write("MIPS16");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_MIPSFPU:
        write("MIPS (w/FPU)");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_MIPSFPU16:
        write("MIPS16 (w/FPU)");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_POWERPC:
        write("PowerPC");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_POWERPCFP:
        write("PowerPC (w/FPU)");
        break;

    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_R4000:
        write("MIPS (Little endian)");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_SH3:
        write("Hitachi SH3");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_SH3DSP:
        write("Hitachi SH3 DSP");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_SH4:
        write("Hitachi SH4");
        break;

    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_SH5:
        write("Hitachi SH5");
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_THUMB:
        write(`ARM or Thumb ("interworking")`);
        break;
        
    case PE_MACHINE_TYPE.IMAGE_FILE_MACHINE_WCEMIPSV2:
        write("MIPS WCE v2 (Little endian)");
        break;
    }

    writeln(" systems");
}

/**
 * ELF File Scanner | __ELF
 */

const size_t EI_NIDENT = 16;
struct Elf32_Ehdr
{
    public char[EI_NIDENT] e_ident;
    public ELF_e_type e_type;
    public ELF_e_machine e_machine;
    public ELF_e_version e_version;
    public uint e_entry;
    public uint e_phoff;
    public uint e_shoff;
    public uint e_flags;
    public ushort e_ehsize;
    public ushort e_phentsize;
    public ushort e_phnum;
    public ushort e_shentsize;
    public ushort e_shnum;
    public ushort e_shstrndx;
}

enum ELF_e_type : ushort
{
    ET_NONE = 0,        // No file type
    ET_REL = 1,         // Relocatable file
    ET_EXEC = 2,        // Executable file
    ET_DYN = 3,         // Shared object file
    ET_CORE = 4,        // Core file
    ET_LOPROC = 0xFF00, // Processor-specific
    ET_HIPROC = 0xFFFF  // Processor-specific
}

enum ELF_e_machine : ushort
{
    EM_NONE = 0,  // No machine
    EM_M32 = 1,   // AT&T WE 32100
    EM_SPARC = 2, // SPARC
    EM_386 = 3,   // Intel Architecture
    EM_68K = 4,   // Motorola 68000
    EM_88K = 5,   // Motorola 88000
    EM_860 = 7,   // Intel 80860
    EM_MIPS = 8,  // MIPS RS3000
    EM_MIPS_RS4_BE = 10, // MIPS RS4000 Big-Endian
    // Rest is from http://wiki.osdev.org/ELF
    EM_POWERPC = 0x14,
    EM_ARM = 0x28,
    EM_SUPERH = 0xA2,
    EM_IA64 = 0x32,
    EM_AMD64 = 0x3E,
    EM_AARCH64 = 0xB7
}

enum ELF_e_version : uint
{
    EV_NONE = 0,
    EV_CURRENT = 1
}

static void scan_elf(File file)
{
    if (_debug)
        writefln("L%04d: Started scanning ELF file", __LINE__);

    Elf32_Ehdr header;

    {
        ubyte[Elf32_Ehdr.sizeof] buf;
        file.rewind();
        file.rawRead(buf);

        byte* pbuf = cast(byte*)&buf, pheader = cast(byte*)&header;

        for (size_t i = 0; i < Elf32_Ehdr.sizeof; ++i)
            *(pheader + i) = *(pbuf + i);
    }

    if (_debug)
    {
        write("e_ident: ");
        foreach (c; header.e_ident)
            writef("%02X ", c);
        writeln();
    }

    if (_debug || _more)
    {
        writefln("type: %s", header.e_type);
        writefln("machine: %s", header.e_machine);
        writefln("version: %s", header.e_version);
        writefln("entry: %s", header.e_entry);
        writefln("phoff: %s", header.e_phoff);
        writefln("shoff: %s", header.e_shoff);
        writefln("flags: %s", header.e_flags);
        writefln("ehsize: %s", header.e_ehsize);
        writefln("phentsize: %s", header.e_phentsize);
        writefln("phnum: %s", header.e_phnum);
        writefln("shentsize: %s", header.e_shentsize);
        writefln("shnum: %s", header.e_shnum);
        writefln("shstrndx: %s", header.e_shstrndx);
    }

    writef("%s: ELF", file.name);

    switch (header.e_ident[4])
    {
    default:
    case 0: // Invalid class
        write(" (Invalid) ");
        break;
    case 1: // 32-bit objects
        write("32 ");
        break;
    case 2: // 64-bit objects
        write("64 ");
        break;
    }

    switch (header.e_type)
    {
    default:
    case ELF_e_type.ET_NONE:
        write("(No file type)");
        break;

    case ELF_e_type.ET_REL:
        write("Relocatable file");
        break;

    case ELF_e_type.ET_EXEC:
        write("Executable file");
        break;

    case ELF_e_type.ET_DYN:
        write("Shared object file");
        break;

    case ELF_e_type.ET_CORE:
        write("Core file");
        break;

    case ELF_e_type.ET_LOPROC:
    case ELF_e_type.ET_HIPROC:
        write("Professor-specific file");
        break;
    }

    write(" for ");

    switch (header.e_machine)
    {
    case ELF_e_machine.EM_NONE:
        write("no");
        break;
        
    case ELF_e_machine.EM_M32:
        write("AT&T WE 32100");
        break;
        
    case ELF_e_machine.EM_SPARC:
        write("SPARC");
        break;
    
    case ELF_e_machine.EM_386:
        write("x86");
        break;
        
    case ELF_e_machine.EM_68K:
        write("Motorola 68000");
        break;
        
    case ELF_e_machine.EM_88K:
        write("Motorola 88000");
        break;
        
    case ELF_e_machine.EM_860:
        write("Intel 80860");
        break;
        
    case ELF_e_machine.EM_MIPS:
        write("MIPS RS3000");
        break;

    case ELF_e_machine.EM_POWERPC:
        write("PowerPC");
        break;

    case ELF_e_machine.EM_ARM:
        write("ARM");
        break;

    case ELF_e_machine.EM_SUPERH:
        write("SuperH");
        break;

    case ELF_e_machine.EM_IA64:
        write("IA64");
        break;

    case ELF_e_machine.EM_AMD64:
        write("x86-64");
        break;

    case ELF_e_machine.EM_AARCH64:
        write("AArch64");
        break;

    default:
        write("unknown");
        break;
    }

    write(" ");

    switch (header.e_ident[5])
    {
    default:
    case 0:
        write("(Invalid)");
        break;
    case 1:
        write("(Little-endian)");
        break;
    case 2:
        write("(Big-endian)");
        break;
    }

    writeln(" systems");
}

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