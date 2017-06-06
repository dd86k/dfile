/*
 * main.d : CLI Main entry point.
 */

module main;

import std.stdio, std.file;
import dfile;
import std.getopt;

/// Debugging version, usually ahead of stable.
debug enum PROJECT_VERSION = "0.7.0-debug";
else  enum PROJECT_VERSION = "0.7.0-git"; /// Project version.

/// Project name, usually the name of the executable.
enum PROJECT_NAME = "dfile";

debug { } else
{ // --DRT-gcopt related
    extern (C) __gshared bool
        rt_envvars_enabled = false, /// Disables runtime environment variables
        rt_cmdline_enabled = false; /// Disables runtime CLI
}

/**
 * Main entry point from CLI.
 * Params: args = CLI arguments.
 * Returns: Error code
 */
int main(string[] args)
{
    bool cont, // Continue with symlinks
         glob, // Use GLOBBING explicitly
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
            "base10|b", "Use decimal metrics instead of binary.", &Base10,
            config.bundling, config.caseSensitive,
            "continue|c", "Continue on soft symlink.", &cont,
            config.bundling, config.caseSensitive,
			"more|m", "Print more information if available.", &More,
            config.bundling, config.caseSensitive,
			"showname|s", "Show filename before result.", &ShowingName,
            config.bundling, config.caseSensitive,
            "glob|g", "Use globbing.", &glob,
            config.bundling, config.caseSensitive,
			"recursive|r", "Recursive (for glob).", &recursive,
            "version|v", "Print version information.", &PrintVersion);
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
            
            if (glob) {
                import std.path : globMatch, dirName;
                debug dbg("GLOB ON");
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
        if (cont) goto FILE;
        else report_link(filename);
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
    writefln("  Usage: %s [<Options>] <File>", PROJECT_NAME);
    writefln("         %s {-h|--help|-v|--version|/?}", PROJECT_NAME);
}

/// Print program version and exit.
void PrintVersion()
{
    import core.stdc.stdlib : exit;
    writefln("%s %s (%s)", PROJECT_NAME, PROJECT_VERSION, __TIMESTAMP__);
debug writefln("Compiled %s with %s v%s", __FILE__, __VENDOR__, __VERSION__);
    writeln("MIT License: Copyright (c) 2016-2017 dd86k");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    exit(0); // getopt hack
}