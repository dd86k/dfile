/*
 * main.d : Main entry point.
 */

module main;

import std.stdio, std.file, std.getopt;
import dfile;

enum PROJECT_VERSION = "0.7.0"; /// Project version.

/// Project name, usually the name of the executable.
enum PROJECT_NAME = "dfile";

debug { } else
{ // --DRT-gcopt related
    extern(C) __gshared bool
        rt_envvars_enabled = false, /// Disables runtime environment variables
        rt_cmdline_enabled = false; /// Disables runtime CLI
}

/**
 * Main entry point from CLI.
 * Params: args = CLI arguments.
 * Returns: Errorcode
 */
int main(string[] args)
{
    if (args.length <= 1)
    {
        PrintHelp;
        return 0;
    }

    bool cont,      // Continue with symlinks
         glob,      // Use GLOBBING explicitly
         recursive; // GLOB - Recursive (breath-first)

    GetoptResult r;
	try {
		r = getopt(args,
            config.bundling, config.caseSensitive,
            "b|base10", "Use decimal metrics instead of a binary base.", &Base10,
            config.bundling, config.caseSensitive,
            "c|continue", "Continue on soft symlink.", &cont,
            config.bundling, config.caseSensitive,
			"m|more", "Print more information if available.", &More,
            config.bundling, config.caseSensitive,
			"n|name", "Prepend filename to result.", &ShowingName,
            config.bundling, config.caseSensitive,
            "g|glob", "Use file match globbing.", &glob,
            config.bundling, config.caseSensitive,
			"r|recursive", "Recursive (glob).", &recursive,
            "v|version", "Print version information.", &PrintVersion
        );
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
        return 0;
	}

    foreach (string filename; args[1..$]) {
        if (exists(filename)) {
            prescan(filename, cont);
        } else {
            if (glob) {
                import std.path : globMatch, dirName;
                int nbf; // Number of files
                foreach (DirEntry e;
                    dirEntries(dirName(filename),
                    recursive ? SpanMode.breadth : SpanMode.shallow, cont)) {
                    immutable char[] s = e.name;
                    if (isFile(s) && globMatch(s, filename)) {
                        ++nbf;
                        prescan(s, cont);
                    }
                    if (!nbf) { // "Not found"-case if 0 files.
                        writeln("No files were found.");
                        return 1;
                    }
                }
            } else {
                if (ShowingName)
                    writef("%s: ", filename);
                
                writeln("File not found.");
                return 1;
            }
        }
    }

    return 0;
}

/**
 * Determines the type of thing from its filename.
 * Params:
 *   filename = Path
 *   cont = Continue on softlink
 */
void prescan(string filename, bool cont)
{
    //TODO: #6 (Posix) -- Use stat(2)
    if (isSymlink(filename))
        if (cont)
            goto FILE;
        else
            report_link(filename);
    else if (isFile(filename))
    {
FILE:
        import std.exception : ErrnoException;
        try
        {
            debug dbg("Opening file...");
            CurrentFile = File(filename, "rb");
        }
        catch (ErrnoException)
        { // At this point, it is a broken symbolic link.
            writeln("Cannot open target file from symlink, exiting");
            return;
        }

        debug dbg("Scanning...");
        scan(CurrentFile);

        debug dbg("Closing file...");
        CurrentFile.close();
    }
    else if (isDir(filename))
    {
        if (ShowingName)
            writef("%s: ", filename);
        writeln("Directory");
    }
    else
        report_unknown(filename);
}

/// Print description and synopsis.
void PrintHelp()
{
    writeln("Determine the file type via magic.");
    writefln("  Usage: %s [options] file", PROJECT_NAME);
    writefln("         %s {-h|--help|-v|--version|/?}", PROJECT_NAME);
}

/// Print program version and exit.
void PrintVersion()
{
    import core.stdc.stdlib : exit;
    writefln("%s %s (%s)", PROJECT_NAME, PROJECT_VERSION, __TIMESTAMP__);
debug writefln("Compiled %s with %s v%s", __FILE__, __VENDOR__, __VERSION__);
    writeln("MIT License: Copyright (c) 2016-2017 dd86k");
    writefln("Project page: <https://github.com/dd86k/%s>", PROJECT_NAME);
    exit(0); // getopt hack
}