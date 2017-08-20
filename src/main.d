/*
 * main.d : Main entry point.
 */

module main;

import std.stdio, std.file, std.getopt;
import dfile;

enum PROJECT_VERSION = "0.8.2", /// Project version.
     PROJECT_NAME = "dfile";    /// Project name, usually executable name.

debug { } else
{ // --DRT-gcopt  related
    private extern(C) __gshared bool
        rt_envvars_enabled = false, /// Disables runtime environment variables
        rt_cmdline_enabled = false; /// Disables runtime CLI
}

private int main(string[] args)
{
    if (args.length <= 1)
    {
        PrintHelp;
        return 0;
    }

    bool cont,      // Continue with symlinks
         glob,      // Use GLOBBING explicitly
         recursive; // GLOB - Recursive (default: shallow)

    GetoptResult r;
	try {
		r = getopt(args,
            config.bundling, config.caseSensitive,
            "b|base10", "Use decimal metrics instead of a binary base.", &Base10,
            config.bundling, config.caseSensitive,
            "c|continue", "Continue on symlink.", &cont,
            config.bundling, config.caseSensitive,
			"m|more", "Print more information if available.", &More,
            config.bundling, config.caseSensitive,
			"s|showname", "Prepend filename to result.", &ShowingName,
            config.bundling, config.caseSensitive,
            "g|glob", "Use file match globbing.", &glob,
            config.bundling, config.caseSensitive,
			"r|recursive", "Recursive (with --glob).", &recursive,
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
        // Overrides glob in-case the filename contains specical characters
        if (exists(filename)) {
            prescan(filename, cont);
        } else {
            if (glob) {
                import std.path : globMatch, dirName;
                int found; // Number of files
                try {
                    foreach (DirEntry e; dirEntries(dirName(filename),
                        recursive ? SpanMode.breadth : SpanMode.shallow, cont)) {
                        immutable char[] s = e.name;
                        if (globMatch(s, filename)) {
                            ++found;
                            prescan(s, cont);
                        }
                    }
                } catch (FileException ex) { // dirEntries may throw
                    stderr.writeln(ex.msg);
                    return 1;
                }
                if (!found) { // "Not found"-case if 0 files.
                    writeln("No files were found.");
                    return 1;
                }
            } else { // non-glob
                report("File not found.", true, filename);
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
    // Or rather, figure a few linux things
    const uint a = getAttributes(filename);
    if (attrIsSymlink(a))
        if (cont)
            goto FILE;
        else
            report_link(filename);
    else if (attrIsFile(a))
    {
        import std.exception : ErrnoException;
FILE:
        try {
            debug dbg("Opening file...");
            CurrentFile = File(filename, "rb");
        } catch (ErrnoException ex) {
            stderr.writeln("Error: ", ex.msg, ".");
            return;
        }

        debug dbg("Scanning...");
        scan();

        debug dbg("Closing file...");
        CurrentFile.close();
    }
    else if (attrIsDir(a))
        report("Directory", true, filename);
    else
        report_unknown(filename);
}

/// Print description and synopsis.
void PrintHelp()
{
    writeln("Determine the file type via pre-determined magic.");
    printf("  Usage: %s [options] file\n", &PROJECT_NAME[0]);
    printf("         %s {-h|--help|-v|--version}\n", &PROJECT_NAME[0]);
}

/// Print program version and exit.
void PrintVersion()
{
    import core.stdc.stdlib : exit;
    printf("%s %s (%s)\n",
        &PROJECT_NAME[0], &PROJECT_VERSION[0], &__TIMESTAMP__[0]);
    printf("Compiled %s with %s v%d\n",
        &__FILE__[0], &__VENDOR__[0], __VERSION__);
    writeln("MIT License: Copyright (c) 2016-2017 dd86k");
    printf("Project page: <https://github.com/dd86k/%s>\n", &PROJECT_NAME[0]);
    exit(0); // getopt hack
}