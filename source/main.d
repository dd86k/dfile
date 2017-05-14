/*
 * main.d : CLI Main entry point.
 */

module main;

import std.stdio, std.file;
import dfile;

debug enum PROJECT_VERSION = "0.7.0-debug";
else  enum PROJECT_VERSION = "0.6.0";

enum PROJECT_NAME = "dfile";

debug { } else
{
    extern (C) __gshared bool
        rt_envvars_enabled = false, rt_cmdline_enabled = false;
}

int main(string[] args)
{
    import std.getopt;

    bool cont, // Continue with symlinks
         recursive; // GLOB - Recursive (breath-first)

    if (args.length <= 1)
    {
        PrintHelp;
        return 0;
    }

    GetoptResult r;
	try {
		r = getopt(args,
            config.bundling, config.caseSensitive,
            "base10|b", "Use decimal metrics instead of binary", &Base10,
            config.bundling, config.caseSensitive,
            "continue|c", "Continue on soft symlink", &cont,
            config.bundling, config.caseSensitive,
			"more|m", "Print more information if available", &More,
            config.bundling, config.caseSensitive,
			"showname|s", "Show filename before result", &ShowingName,
            config.bundling, config.caseSensitive,
			"recursive|r", "Recursive (for glob)", &recursive,
            "version|v", "Print version information", &PrintVersion);
	} catch (GetOptException ex) {
		stderr.writeln("Error: ", ex.msg);
        return 1;
	}

    if (r.helpWanted) {
        PrintHelp;
        writeln("\nOption             Description");
        foreach (it; r.options) { // "custom" defaultGetoptPrinter
            writefln("%*s, %-*s%s%s",
                4,  it.optShort,
                12, it.optLong,
                it.required ? "Required: " : " ",
                it.help);
        }
	} else {
        //TODO: Multiple entries (chained)
        string filename = args[$ - 1]; // Last argument, no exceptions!

        if (exists(filename)) {
            prescan(filename, cont);
        } else {
            import std.string : indexOf;
            // No point to do globbing if there are no metacharacters
            if (globTime(filename)) {
                import std.path : globMatch, dirName;
                debug writeln("GLOB ON");
                int nbf; // Number of files
                foreach (DirEntry e;
                    dirEntries(dirName(filename),
                    recursive ? SpanMode.breadth : SpanMode.shallow, cont)) {
                    immutable char[] s = e.name;
                    if (isFile(s) && globMatch(s, filename)) {
                        ++nbf;
                        prescan(s, cont);
                    }
                }
                if (!nbf) { // "Not found"-case if 0 files.
                    ShowingName = false;
                    goto CLI_NOTFOUND;
                }
            } else { // No glob!
CLI_NOTFOUND:
                report("File does not exist");
                return 1;
            }
        }
	}

    return 0;
}

void prescan(string filename, bool cont)
{
    //TODO: #6 (Posix) -- Use stat(2)
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

/**
 * Determines if it's GLOB time!
 * Params: s = String to evalutate
 * Returns: True if GLOB time.
 */
bool globTime(const char[] s) pure @nogc
{
    const size_t l = s.length;
    for (int i; i < l; ++i) {
        switch (s[i]) {
            case '[', ']', '*', '?':
                return true;
                /*if (i - 1 >= 0)
                    if (s[i] != '\\')
                        return true;
                break;*/
            default:
        }
    }
    return false;
}

void PrintHelp()
{
    writeln("Determine the file type by its magic.");
    writefln("  Usage: %s [<Options>] <File>", PROJECT_NAME);
    writefln("         %s {-h|--help|-v|--version|/?}", PROJECT_NAME);
}

void PrintVersion()
{
    import core.stdc.stdlib : exit;
    writefln("%s %s (%s)", PROJECT_NAME, PROJECT_VERSION, __TIMESTAMP__);
    writeln("MIT License: Copyright (c) 2016-2017 dd86k");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    writefln("Compiled %s with %s v%s", __FILE__, __VENDOR__, __VERSION__);
    exit(0); // getopt hack
}