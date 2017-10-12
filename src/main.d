/*
 * main.d : Main entry point.
 */

module main;

import core.stdc.stdio : printf, fclose, stderr, fopen;
import std.stdio : writeln, writefln, _wfopen;
import std.file, std.getopt;
import std.encoding : transcode;
import dfile;

enum PROJECT_VERSION = "0.10.0", /// Project version.
     PROJECT_NAME = "dfile";     /// Project name, usually executable name.

debug { } else
{ // --DRT-gcopt  related
    extern(C) __gshared bool
        rt_envvars_enabled = false, /// Disables runtime environment variables
        rt_cmdline_enabled = false; /// Disables runtime CLI
}

private int main(string[] args)
{
    import std.path : globMatch, dirName;

    if (args.length <= 1) {
        PrintHelp;
        return 0;
    }

    bool cont,      // Continue with symlinks
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
			"s|showname", "Prepend filename to result.", &ShowName,
            config.bundling, config.caseSensitive,
			"r|recursive", "Recursive (depth-first pre-order).", &recursive,
            "v|version", "Print version information.", &PrintVersion
        );
	} catch (GetOptException ex) {
		stderr.writeln("Error: ", ex.msg);
        return 1;
	}

    if (r.helpWanted) {
        PrintHelp;
        printf("\nOption             Description\n");
        foreach (it; r.options) { // "custom" defaultGetoptPrinter
            writefln("%*s, %-*s%s%s",
                4,  it.optShort,
                12, it.optLong,
                it.required ? "Required: " : " ",
                it.help);
        }
        return 0;
	}

    int found; // Number of files found
    foreach (string fn; args[1..$]) { // `fn` to avoid shadowing variable `filename`
        try {
            foreach (DirEntry e; dirEntries(dirName(fn),
                recursive ? SpanMode.breadth : SpanMode.shallow, cont)) {
                // Somehow using e.name directly generates less machine code
                if (globMatch(e.name, fn)) {
                    ++found;
                    prescan(e.name, cont);
                }
            }
        } catch (FileException ex) { // dirEntries may throw (on what?)
            stderr.writeln(ex.msg);
            return 1;
        }
    }
    if (!found) { // "Not found"-case if 0 files.
        printf("No files were found.\n");
        return 1;
    }

    return 0;
}

/**
 * Determines the type of thing from its filename.
 * Params:
 *   path = Path
 *   cont = Continue on softlink
 */
void prescan(string path, bool cont)
{
    version (Windows)
        uint a = getAttributes(path);
    else
        const uint a = getAttributes(path);
    filename = path ~ '\0';
    version (Posix) { // Linux, BSD, UNIX, etc.
        import core.sys.posix.sys.stat :
            S_IFBLK, S_IFCHR, S_IFIFO, S_IFREG, S_IFDIR, S_IFLNK, S_IFSOCK, S_IFMT;
        if (a & S_IFLNK)
            if (cont)
                goto FILE;
            else
                report_link();
        else if (a & S_IFREG) {
FILE:
            fp = fopen(&filename[0], "r");
            if (!fp) {
                printf("There was an error opening the file.\n");
                return;
            }

            debug dbg("Scanning...");
            scan();

            debug dbg("Closing file...");
            fclose(fp);
        }
        else if (a & S_IFCHR)
            report("Character special");
        else if (a & S_IFBLK)
            report("Block");
        else if (a & S_IFSOCK)
            report("Socket");
        else if (a & S_IFDIR)
            report("Directory");
        else
            report_unknown;
    } else version (Windows) { // Windows
        import core.sys.windows.winnt :
            FILE_ATTRIBUTE_DIRECTORY, FILE_ATTRIBUTE_REPARSE_POINT;
        if (a & FILE_ATTRIBUTE_REPARSE_POINT)
            if (cont)
                goto FILE;
            else
                report_link();
        else if ((a = a & FILE_ATTRIBUTE_DIRECTORY) == 0) {
FILE:
            debug dbg("Opening file...");
            wstring ws;
            transcode(filename, ws);
            fp = _wfopen(&ws[0], "r");
            if (!fp) {
                printf("There was an error opening the file.\n");
                return;
            }
            debug dbg("Scanning...");
            scan();

            debug dbg("Closing file...");
            fclose(fp);
        } else if (a) // "a" already set with FILE_ATTRIBUTE_DIRECTORY earlier
            report("Directory");
        else
            report_unknown();
    } else {
        static assert(0, "Implement prescan");
    }
}

/// Print description and synopsis.
void PrintHelp()
{
    printf("Determine the file type via pre-determined magic.\n");
    printf("  Usage: dfile [options] file\n");
    printf("         dfile {-h|--help|-v|--version}\n");
}

/// Print program version and exit.
void PrintVersion()
{
    import core.stdc.stdlib : exit;
    printf("dfile %s (%s)\n", &PROJECT_VERSION[0], &__TIMESTAMP__[0]);
    printf("Compiled at %s with %s v%d\n", &__FILE__[0], &__VENDOR__[0], __VERSION__);
    printf("MIT License: Copyright (c) 2016-2017 dd86k\n");
    printf("Project page: <https://github.com/dd86k/dfile>\n");
    exit(0); // getopt hack
}