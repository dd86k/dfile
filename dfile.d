import std.stdio : write, writeln, writef, writefln, File;
import std.file : exists, isDir;

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
                writeln("Debugging mode turned on.");
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
                    writefln("L%04d: Opening file...", __LINE__);
                File f = File(filename, "rb");
                
                if (_debug)
                    writefln("L%04d: Scaning file...", __LINE__);
                scan_file(f);
                
                if (_debug)
                    writefln("L%04d: Closing file...", __LINE__);
                f.close();
            }
        }
        else
        {
            writeln("File does not exist.");
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
    writeln("  -h     Print help and exit.");
    writeln("  -v     Print version and exit.");
    writeln("  -d, --debug     Print debugging information.");
}

static void print_version()
{
    writeln("dfile - v%s", PROJECT_VERSION);
    writeln("Copyright (c) 2016 dd86k");
    writeln("License: MIT");
    writeln("Project page: ...");
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
        writefln("L%04d: Reading file...", __LINE__);
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
            report(file, "Computer icon encoded in ICO file format");
            break;

        case [0x66, 0x74, 0x79, 0x70]:
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
                }
            }
            break;

        case [0x42, 0x41, 0x43, 0x4B]:
            {
                file.rawRead(magic);
                string s = cast(string)magic;

                switch (s)
                {
                    case [0x4D, 0x49, 0x4B, 0x45]:
                    {
                        file.rawRead(magic);
                        s = cast(string)magic;

                        switch (s)
                        {
                            case [0x44, 0x49, 0x53, 0x4B]:
                                report(file, "File or tape containing a backup done with AmiBack on an Amiga.");
                                break;

                            default:
                        }
                    }
                    break;

                    default:
                }
            }
            break;

        //case [0x42, 0x5A, 0x68]: //BZh - Compressed file using Bzip2 algorithm

        case [0x47, 0x49, 0x46, 0x38]:
            {
                byte[2] b;
                file.rawRead(b);

                string s = cast(string)b;

                switch (s)
                {
                    case [0x37, 0x61]:
                        report(file, "GIF87a");
                        break;
                    case [0x39, 0x61]:
                        report(file, "GIF89a");
                        break;

                    default:
                }
            }
            break;

        case [0x49, 0x49, 0x2A, 0x00]:
        case [0x4D, 0x4D, 0x00, 0x2A]:
            report(file, "TIFF");
            break;

        case [0x80, 0x2A, 0x5F, 0xD7]:
            report(file, "Kodak Cineon image");
            break;

        case [0x52, 0x4E, 0x43, 0x01]:
            {
                byte[4] b;
                file.rawRead(b);

                string s = cast(string)b;

                switch (s)
                {
                    case [0x52, 0x4E, 0x43, 0x02]:
                        report(file, "Compressed file using Rob Northen Compression (version 1 and 2) algorithm");
                        break;

                    default:
                }
            }
            break;

        case [0x53, 0x44, 0x50, 0x58]:
        case [0x58, 0x50, 0x44, 0x53]:
            report(file, "SMPTE DPX image");
            break;

        case [0x76, 0x2F, 0x31, 0x01]:
            report(file, "OpenEXR image");
            break;

        case [0x42, 0x50, 0x47, 0xFB]:
            report(file, "Better Portable Graphics format");
            break;

        case [0xFF, 0xD8, 0xFF, 0xDB]:
        case [0xFF, 0xD8, 0xFF, 0xE0]:
        case [0xFF, 0xD8, 0xFF, 0xE1]:
            report(file, "JPEG");
            break;

        default:
            {
                byte[2] b;
                file.rewind();
                file.rawRead(b);
                string s = cast(string)b;

                switch (s)
                {
                    case [0x1F, 0x9D]:
                        report(file, "compressed file (often tar zip) using Lempel-Ziv-Welch algorithm");
                        break;
                    case [0x1F, 0xA0]:
                        report(file, "compressed file (often tar zip) using LZH algorithm");
                        break;

                    default:
                }

                report(file, "Unknown (yet)");
            }
            break;
    }
}

static void report(File file, string type)
{
    writefln("%s: %s", file.name, type);
}