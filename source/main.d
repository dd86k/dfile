/*
 * main.d : CLI Main entry point.
 */

module main;

import std.stdio;
import std.file;
import dfile;

enum
    PROJECT_NAME = "dfile",
    PROJECT_VERSION = "0.6.0";

debug { }
else
{
    extern (C) __gshared bool
        rt_envvars_enabled = false, rt_cmdline_enabled = false;
}

int main(string[] args)
{
    size_t l = args.length;

    if (l <= 1)
    {
        print_help;
        return 0;
    }

    bool cont;

    for (int i; i < l; ++i)
    {
        switch (args[i])
        {
        case "-s", "--showname":
            ShowingName = true;
            break;
        case "-m", "--more":
            More = true;
            break;
        case "-c", "--continue":
            cont = true;
            break;
        case "-b", "--base10":
            Base10 = true;
            break;

        case "-h":
            print_help;
            return 0;
        case "--help", "/?":
            print_help_full;
            return 0;
        case "-v", "--version":
            print_version;
            return 0;
        default:
        }
    }

    string filename = args[l - 1]; // Last argument, no exceptions!

    if (exists(filename))
    {
        if (isSymlink(filename))
            if (cont)
                scan(filename);
            else
                report_link(filename);
        else if (isFile(filename))
            scan(filename);
        else if (isDir(filename))
            report_dir(filename);
        else
            report_unknown(filename);
    }
    else
    {
        report("File does not exist");
        return 1;
    }

    return 0;
}

void print_help()
{
    // CLI RULER
    //      1        10        20        30       40        50        60        70        80
    //      |--------|---------|---------|--------|---------|---------|---------|---------|
    writeln("Determine the file type by its content.");
    writeln("  Usage: ", PROJECT_NAME, " [<Options>] <File>");
    writeln("         ", PROJECT_NAME, " {-h|--help|-v|--version|/?}");
}

void print_help_full()
{
    print_help();
    // CLI RULER
    //       1        10        20        30       40        50        60        70        80
    //       |--------|---------|---------|--------|---------|---------|---------|---------|
    writeln("  Option           Description (Default value)");
    writeln("  -b, --base10     Use decimal metrics instead of binary. (Off)");
    writeln("  -s, --showname   Show filename before result. (Off)");
    writeln("  -c, --continue   Continue on soft symlink. (Off)");
    writeln("  -m, --more       Print more information if available. (Off)");
    //writeln("  -o, --more-os   Use system functions to get more information. (Off)");
    //e.g. https://msdn.microsoft.com/en-us/library/windows/desktop/aa364819(v=vs.85).aspx
    writeln();
    writeln("  -h, --help, /?   Print help and exit");
    writeln("  -v, --version    Print version and exit");
}

void print_version()
{
debug
    writeln(PROJECT_NAME, " ", PROJECT_VERSION, "-debug (", __TIMESTAMP__, ")");
else
    writeln(PROJECT_NAME, " ", PROJECT_VERSION, " (", __TIMESTAMP__, ")");
    writeln("MIT License: Copyright (c) 2016-2017 dd86k");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    writeln("Compiled ", __FILE__, " with ", __VENDOR__, " v", __VERSION__);
}