import std.stdio : write, writeln, writef, writefln, File;
import std.file : exists, isDir;
import std.exception;

const string PROJECT_NAME = "dfile";
const string PROJECT_VERSION = "0.0.0";

static bool _debug;

/*
https://en.wikipedia.org/wiki/List_of_file_signatures
https://mimesniff.spec.whatwg.org
*/

static int main(string[] args)
{
    int arglen = args.length - 1;

    if (arglen == 0)
    {
        print_help;
        return 0;
    }

    string filename = args[arglen];

    for (int i = 0; i < arglen; ++i)
    {
        switch (args[i])
        {
            case "-d":
            case "--debug":
                _debug = true;
                writeln("Debugging mode turned on");
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

    if (filename != null)
    {
        if (exists(filename))
        {
            if (isDir(filename))
            {
                writefln("%s: Directory", filename);
                return 0;
            }
            else
            {
                if (_debug)
                    writefln("L%04d: Opening file..", __LINE__);
                File f = File(filename, "rb");
                
                if (_debug)
                    writefln("L%04d: Scaning file..", __LINE__);
                scan_file(f);
                
                if (_debug)
                    writefln("L%04d: Closing file..", __LINE__);
                f.close();
            }
        }
        else
        {
            writeln("File does not exist");
            return 1;
        }
    }

    return 0;
}

static void print_help()
{
    writefln(" Usage: %s [<Options>] [<File>]", PROJECT_NAME);
    writefln("        %s [-h|--help|-v|--version]", PROJECT_NAME);
}

static void print_help_full()
{
    writefln(" Usage: %s [<Options>] <File>", PROJECT_NAME);
    writeln("Determine the nature of the file.\n");
    writeln("  -h     Print help and exit");
    writeln("  -v     Print version and exit");
    writeln("  -d, --debug     Print debugging information");
}

static void print_version()
{
    writeln("dfile - v%s", PROJECT_VERSION);
    writeln("Copyright (c) 2016 dd86k");
    writeln("License: MIT");
    writeln("Project page: ..");
}

static void scan_file(File file)
{
    if (file.size == 0)
    {
        report(file, "Empty file");
        return;
    }

    byte[4] magic;
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
            report(file, "Palm Desktop Calendar Archive (DBA)");
            break;

        case [0x00, 0x01, 0x42, 0x44]:
            report(file, "Palm Desktop To Do Archive (DBA)");
            break;

        case [0x00, 0x01, 0x44, 0x54]:
            report(file, "Palm Desktop Calendar Archive (TDA)");
            break;

        case [0x00, 0x01, 0x00, 0x00]:
            report(file, "Palm Desktop Data File (Access format)");
            break;

        case [0x00, 0x00, 0x01, 0x00]:
            report(file, "Icon, ICO format");
            break;

        case "ftyp":
            {
                byte[2] b;
                file.rawRead(b);

                const string s = cast(string)b;

                switch (s)
                {
                    case [0x33, 0x67]:
                        report(file, "3rd Generation Partnership Project 3GPP and 3GPP2 multimedia files");
                        break;

                    default:
                        report_unknown(file);
                        break;
                }
            }
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
                                report(file, "AmiBack backup");
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
                byte[2] b;
                file.rawRead(b);

                string s = cast(string)b;

                switch (s)
                {
                    case "7a":
                        report(file, "GIF87a");
                        break;
                    case "9a":
                        report(file, "GIF89a");
                        break;

                    default:
                }
            }
            break;

        case ['I', 'I', '*', 0x00]:
            {
                byte[6] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case [0x10, 0, 0, 0, 'C', 'R']:
                        report(file, "Canon RAW Format Version 2 image (TIFF)");
                        break;

                    default:
                        report(file, "Tagged Image File Format image (TIFF)");
                        break;
                }
            }
            break;

        case ['M', 'M', 0x00, '*']:
            report(file, "Tagged Image File Format image (TIFF)");
            break;

        case [0x80, 0x2A, 0x5F, 0xD7]:
            report(file, "Kodak Cineon image");
            break;

        case ['R', 'N', 'C', 0x01]:
        case ['R', 'N', 'C', 0x02]:
            report(file, "Compressed file (Rob Northen Compression v1/v2)");
            break;

        case "SDPX":
        case "XPDS":
            report(file, "SMPTE DPX image");
            break;

        case [0x76, 0x2F, 0x31, 0x01]:
            report(file, "OpenEXR image");
            break;

        case "BPGû":
            report(file, "Better Portable Graphics image (BPG)");
            break;

        case [0xFF, 0xD8, 0xFF, 0xDB]:
        case [0xFF, 0xD8, 0xFF, 0xE0]:
        case [0xFF, 0xD8, 0xFF, 0xE1]:
            report(file, "Joint Photographic Experts Group image (JPEG)");
            break;
            
        case "FORM":
            {
                byte[4] b;
                file.seek(8, 0);
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "ILBM":
                        report(file, "IFF Interleaved Bitmap Image");
                        break;
                    case "8SVX":
                        report(file, "IFF 8-Bit Sampled Voice");
                        break;
                    case "ACBM":
                        report(file, "Amiga Contiguous Bitmap");
                        break;
                    case "ANBM":
                        report(file, "IFF Animated Bitmap");
                        break;
                    case "ANIM":
                        report(file, "IFF CEL Animation");
                        break;
                    case "FAXX":
                        report(file, "IFF Facsimile Image");
                        break;
                    case "FTXT":
                        report(file, "IFF Formatted Text");
                        break;
                    case "SMUS":
                        report(file, "IFF Simple Musical Score");
                        break;
                    case "CMUS":
                        report(file, "IFF Musical Score");
                        break;
                    case "YUVN":
                        report(file, "IFF YUV Image");
                        break;
                    case "FANT":
                        report(file, "Amiga Fantavision Movie");
                        break;
                    case "AIFF":
                        report(file, "Audio Interchange File Format");
                        break;
                    default:
                }
            }
            break;

        case "INDX":
            report(file, "AmiBack backup index file");
            break;

        case "LZIP":
            report(file, "lzip compressed file");
            break;

        case ['P', 'K', 0x03, 0x04]:
        case ['P', 'K', 0x05, 0x06]:
        case ['P', 'K', 0x07, 0x08]:
            report(file, "ZIP compressed file (or JAR, ODF, OOXML)");
            break;

        case "Rar!":
            {
                byte[4] b;
                file.rawRead(b);

                string s = cast(string)b;

                switch (s)
                {
                    case [0x1A, 0x07, 0x01, 0x00]:
                        report(file, "RAR archive v5.0+");
                        break;
                    default:
                        report(file, "RAR archive v1.5+");
                        break;
                }
            }
            break;

        case [0x7F, 'E', 'L', 'F']:
            report(file, "Executable and Linkable Format binary (ELF)");
            break;

        case [0x89, 'P', 'N', 'G']:
            {
                byte[4] b;
                file.rawRead(b);

                string s = cast(string)b;

                switch (s)
                {
                    case [0x0D, 0x0A, 0x1A, 0x0A]:
                        report(file, "Portable Network Graphics image (PNG)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case [0xCA, 0xFE, 0xBA, 0xBE]:
            report(file, "Java class file, Mach-O Fat Binary");
            break;

        case [0xFE, 0xED, 0xFA, 0xCE]:
            report(file, "Mach-O binary (32-bit)");
            break;

        case [0xFE, 0xED, 0xFA, 0xCF]:
            report(file, "Mach-O binary (64-bit)");
            break;

        case [0xCE, 0xFA, 0xED, 0xFE]:
            report(file, "Mach-O binary (32-bit, Reversed)");
            break;

        case [0xCF, 0xFA, 0xED, 0xFE]:
            report(file, "Mach-O binary (64-bit, Reversed)");
            break;

        case [0xFF, 0xFE, 0x00, 0x00]:
            report(file, "UTF-32 text file (byte-order mark)");
            break;

        case "%!PS":
            report(file, "PostScript document");
            break;

        case "%PDF":
            report(file, "PDF document");
            break;

        case [0x30, 0x26, 0xB2, 0x75]:
            {
                byte[12] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case [0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9, 0, 0xAA, 0, 0x62, 0xCE, 0x6C]:
                        report(file, "Advanced Systems Format file (ASF, WMA, WMV)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case "$SDI":
            {
                byte[4] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case [0x30, 0x30, 0x30, 0x31]:
                        report(file, "System Deployment Image (Microsoft disk image)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case "OggS":
            report(file, "Ogg audio file");
            break;

        case "8BPS":
            report(file, "Photoshop native document file");
            break;

        case "RIFF":
            {
                byte[4] b;
                file.seek(8);
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "WAVE":
                        report(file, "Waveform Audio File (wav)");
                        break;
                    case "AVI ":
                        report(file, "Audio Video Interface video (avi)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        /*case "CD00": // Offset: 0x8001, 0x8801, 0x9001
            {
                byte[1] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case ['1']:
                        report(file, "ISO9660 CD/DVD image file (ISO)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;*/

        case "SIMP":
            {
                byte[4] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "LE  ":
                        report(file, "Flexible Image Transport System (FITS)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case "fLaC":
            report(file, "Free Lossless Audio Codec audio file (FLAC)");
            break;

        case "MThd":
            report(file, "MIDI sound file");
            break;

        case [0xD0, 0xCF, 0x11, 0xE0]:
            {
                byte[4] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case [0xA1, 0xB1, 0x1A, 0xE1]:
                        report(file, "Compound File Binary Format document (doc, xls, ppt)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case ['d', 'e', 'x', 0x0A]:
            {
                byte[4] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "035\0":
                        report(file, "Dalvik Executable");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case "Cr24":
            report(file, "Google Chrome extension or packaged app (crx)");
            break;

        case "AGD3":
            report(file, "FreeHand 8 document (fh8)");
            break;

        case [0x05, 0x07, 0x00, 0x00]:
            {
                byte[6] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case [0x4F, 0x42, 0x4F, 0x05, 0x07, 0x00]:
                        report(file, "AppleWorks 5 document (cwk)");
                        break;
                    case [0x4F, 0x42, 0x4F, 0x06, 0x07, 0xE1]:
                        report(file, "AppleWorks 6 document (cwk)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case ['E', 'R', 0x02, 0x00]:
            report(file, "Roxio Toast disc image or DMG file (toast or dmg)");
            break;

        case ['x', 0x01, 's', 0x0D]:
            report(file, "Apple Disk Image file (dmg)");
            break;

        case "xar!":
            report(file, "eXtensible ARchive format (xar)");
            break;

        case "PMOC":
            {
                byte[4] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "CMOC":
                        report(file, "USMT, Windows Files And Settings Transfer Repository (dat)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        /*case "usta": // Tar offset 0x101
            {

            }
            break;*/

        case "TOX3":
            report(file, "Open source portable voxel file");
            break;

        case "MLVI":
            report(file, "Magic Lantern Video file");
            break;

        case "DCM\0":
            {
                byte[4] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "PA30":
                        report(file, "Windows Update Binary Delta Compression");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case [0x37, 0x7A, 0xBC, 0xAF, 0x27]:
            {
                byte[1] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case [0x1C]:
                        report(file, "7-Zip compressed file (7z)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case [0x04, 0x22, 0x4D, 0x18]:
            report(file, "LZ4 Streaming Format (lz4)");
            break;

        case "MSCF":
            report(file, "Microsoft Cabinet File (cab)");
            break;

        case "FLIF":
            report(file, "Free Lossless Image Format image file (flif)");
            break;

        case [0x1A, 0x45, 0xDF, 0xA3]:
            report(file, "Matroska media container (mkv, webm)");
            break;

        case "MIL ":
            report(file, `"SEAN : Session Analysis" Training file`);
            break;

        case "AT&T":
            {
                byte[4] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "FORM":
                        {
                            file.seek(4);
                            file.rawRead(b);
                            s = cast(string)b;

                            switch (s)
                            {
                                case "DJVU":
                                    report(file, "DjVu document, single page (djvu)");
                                    break;
                                case "DJVM":
                                    report(file, "DjVu document, multiple pages (djvu)");
                                    break;
                                default:
                                    report_unknown(file);
                                    break;
                            }
                        }
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break;

        case "wOFF":
            report(file, "WOFF File Format 1.0 font (woff)");
            break;

        case "wOF2":
            report(file, "WOFF File Format 2.0 font (woff)");
            break;

        case "<?xm":
            {
                byte[1] b;
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case "m>":
                        report(file, "ASCII XML (xml)");
                        break;
                    default:
                        report_unknown(file);
                        break;
                }
            }
            break; // too lazy for utf-*

        case "\0asm":
            report(file, "WebAssembly file (wasm)");
            break;

        default:
            {
                switch (sig[0..2])
                {
                    case [0x1F, 0x9D]:
                        report(file, "Lempel-Ziv-Welch compressed file (RAR/ZIP)");
                        break;

                    case [0x1F, 0xA0]:
                        report(file, "LZH compressed file (RAR/ZIP)");
                        break;

                    case [0x4D, 0x5A]:
                        report(file, "DOS Executable");
                        break;

                    case [0xFF, 0xFE]:
                        report(file, "UTF-16 text file (Byte-Order mark)");
                        break;

                    case [0xFF, 0xFB]:
                        report(file, "MPEG-2 Audio Layer III audio file (MP3)");
                        break;

                    case "BM":
                        report(file, "Bitmap iamge file (BMP)");
                        break;

                    case [0x1F, 0x8B]:
                        report(file, "GZIP compressed file ([tar.]gz)");
                        break;

                    case [0x30, 0x82]:
                        report(file, "DER encoded X.509 certificate (der)");
                        break;

                    default:
                        switch (sig[0..3])
                        {
                            case "BZh":
                                report(file, "Bzip2 compressed file (BZh)");
                                break;

                            case [0xEF, 0xBB, 0xBF]:
                                report(file, "UTF-8 text file with BOM");
                                break;

                            case "ID3":
                                report(file, "MPEG-2 Audio Layer III audio file with ID3v2 container (MP3)");
                                break;

                            case "KDM":
                                report(file, "VMware Disk K virtual disk file (VMDK)");
                                break;

                            case "NES\xA1":
                                report(file, "Nintendo Entertainment System ROM file (nes)");
                                break;

                            case [0xCF, 0x84, 0x01]:
                                report(file, "Lepton compressed JPEG image (lep)");
                                break;

                            default:
                                report_unknown(file);
                                break;
                        }
                        break;
                }

            }
            break;
    }
}

static void report(File file, string type)
{
    writefln("%s: %s", file.name, type);
}

static void report_unknown(File file)
{
    writefln("%s: Unknown file format", file.name);
}

/**
 * Binary scanners
 */

static void scan_pe(File file)
{
    throw new Exception("TODO: scan_pe");
}

static void scan_elf(File file)
{
    throw new Exception("TODO: scan_elf");
}

static void scan_unknown(File file)
{
    // Scan for readable characters for X(1MB?) bytes and at least Y(3?) characters
    throw new Exception("TODO: scan_unknown");
}