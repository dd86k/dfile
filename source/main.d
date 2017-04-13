/*
 * main.d : CLI Main entry point.
 */

module main;

import std.stdio, std.file, dfile;

enum
    PROJECT_NAME = "dfile",
    PROJECT_VERSION = "0.6.0";

debug { } else
{
    extern (C) __gshared bool
        rt_envvars_enabled = false, rt_cmdline_enabled = false;
}

int main(string[] args)
{
    bool cont; // Continue with symlink, disable by default

    if (args.length <= 1)
    {
        print_help;
        return 0;
    }

    import std.getopt;
    GetoptResult r;
	try {
		r = getopt(args,
            config.bundling,
            "base10|b", "Use decimal metrics instead of binary", &Base10,
            config.bundling,
            "continue|c", "Continue on soft symlink", &cont,
            config.bundling,
			"more|m", "Print more information if available", &More,
            config.bundling,
			"showname|s", "Show filename before result", &ShowingName,
            "version|v", "Print version information", &print_version);
	} catch (GetOptException ex) {
		stderr.writeln(ex.msg);
        return 1;
	}

    if (r.helpWanted)
    {
        print_help;
        writeln("\nSwitches");
        foreach (it; r.options)
        { // "custom" defaultGetoptPrinter
            writefln("%*s, %-*s%s%s",
                4,  it.optShort,
                12, it.optLong,
                it.required ? "Required: " : " ",
                it.help);
        }
	}
    else
    {
        string filename = args[$ - 1]; // Last argument, no exceptions!

        if (exists(filename)) {
            prescan(filename, cont);
        } else {
            import std.string : indexOf;
            // No point to do globbing if there are no metacharacters
            if (indexOf(filename, '*', 0) >= 0 || indexOf(filename, '?', 0) >= 0 ||
                indexOf(filename, '[', 0) >= 0 || indexOf(filename, ']', 0) >= 0) { 
                import std.path : globMatch, dirName;
                debug writeln("GLOB ON");
                int nbf;
                foreach (DirEntry e;
                    dirEntries(dirName(filename), SpanMode.shallow, cont)) {
                    if (globMatch(e.name, filename)) {
                        ++nbf;
                        prescan(e.name, cont);
                    }
                }
                if (!nbf) {
                    ShowingName = false;
                    goto F_NE;
                }
            } else { // No glob!
F_NE:
                report("File does not exist");
                return 1;
            }
        }
	}

    return 0;
}

void prescan(string filename, bool cont)
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

void print_help()
{
    writeln("Determine the file type by its content.");
    writefln("  Usage: %s [<Options>] <File>", PROJECT_NAME);
    writefln("         %s {-h|--help|-v|--version|/?}", PROJECT_NAME);
}

void print_version()
{
    import core.stdc.stdlib : exit;
    debug
        writefln("%s %s-debug (%s)", PROJECT_NAME, PROJECT_VERSION, __TIMESTAMP__);
    else
        writefln("%s %s (%s)", PROJECT_NAME, PROJECT_VERSION, __TIMESTAMP__);
    writeln("MIT License: Copyright (c) 2016-2017 dd86k");
    writeln("Project page: <https://github.com/dd86k/dfile>");
    writefln("Compiled %s with %s v%s", __FILE__, __VENDOR__, __VERSION__);
    exit(0); // Due to getopt, hack
}