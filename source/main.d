/*
 * main.d : CLI Main entry point.
 */

module main;

import std.stdio, dfile;
import std.file : exists, isDir;

enum {
    PROJECT_NAME = "dfile",
    PROJECT_VERSION = "0.5.0"
}

private static int main(string[] args)
{
    size_t l = args.length;
    
    if (l <= 1)
    {
        print_help;
        return 0;
    }

    for (int i; i < l; ++i)
    {
        switch (args[i])
        {
        case "-d", "--debug":
            Debugging = true;
            writeln("Debugging mode turned on");
            break;
        case "-s", "--showname":
            ShowingName = true;
            break;
        case "-m", "--more":
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
        case "-v", "--version":
            print_version;
            return 0;
        default:
        }
    }

    string filename = args[l - 1]; // Last argument, no exceptions!

    if (exists(filename))
    {
        if (isDir(filename))
        {
            report("Directory");
            return 0;
        }
        else
            scan(filename);
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
    writeln("Determine the file type by its content.");
    writeln("  Usage: ", PROJECT_NAME, " [<Options>] <File>");
    writeln("         ", PROJECT_NAME, " {-h|--help|-v|--version|/?}");
}

static void print_help_full()
{
    print_help();
    writeln("  Option           Description (Default value)");
    writeln("  -m, --more       Print more information if available. (Off)");
    writeln("  -s, --showname   Show filename before result. (Off)");
    writeln("  -d, --debug      Print debugging information. (Off)");
    writeln();
    writeln("  -h, --help, /?   Print help and exit");
    writeln("  -v, --version    Print version and exit");
}

static void print_version()
{
    debug
    writeln(PROJECT_NAME, " ", PROJECT_VERSION, "-debug (", __TIMESTAMP__, ")");
    else
    writeln(PROJECT_NAME, " ", PROJECT_VERSION, " (", __TIMESTAMP__, ")");
    writeln("MIT License: Copyright (c) 2016-2017 dd86k");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    writeln("Compiled ", __FILE__, " with ", __VENDOR__, " v", __VERSION__);
}