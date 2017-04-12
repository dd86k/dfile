/*
 * main.d : CLI Main entry point.
 */

module main;

import std.stdio, std.file, dfile;

enum
    PROJECT_NAME = "dfile",
    PROJECT_VERSION = "0.6.0";

debug { }
else
{
    extern (C) __gshared bool
        rt_envvars_enabled = false, rt_cmdline_enabled = false;
}

string[] args;

int main(string[] args_)
{
    args = args_;

    bool cont; // Continue with symlink, disable by default
    bool shwVersion;

    import std.getopt;
    GetoptResult rslt;
	try {
		rslt = getopt(args,
            "base10|b", "", &Base10,
            "continue|c", "Continue on soft symlink", &cont,
			"more|m", "Print more information if available", &More,
			"showname|s", "Show filename before result", &ShowingName,
            "version|v", "Print version information", &shwVersion);
	} catch(GetOptException e) {
        import core.stdc.stdlib : exit;
		stderr.writefln("%s", e.msg);
        exit(1);
	}

    if(args_.length <= 1 || rslt.helpWanted) {
        writeln("Determine the file type by its content.");
		writefln("  Usage: %s [<Options>] <File>", PROJECT_NAME);
        writefln("         %s {-h|--help|-v|--version|/?}", PROJECT_NAME);
        if(rslt.helpWanted)
    	{
    		defaultGetoptPrinter("\nSome information about the program.",
    		rslt.options);
        }
	} else if (shwVersion) {
        debug
            writefln("%s %s -debug (%s)", PROJECT_NAME, PROJECT_VERSION, __TIMESTAMP__);
        else
            writefln("%s %s (%s)", PROJECT_NAME, PROJECT_VERSION, __TIMESTAMP__);
            writeln("MIT License: Copyright (c) 2016-2017 dd86k");
            writeln("Project page: <https://github.com/dd86k/dfile>");
            writefln("Compiled %s with %s v%s", __FILE__, __VENDOR__, __VERSION__);
	} else {
        writeln(args_[1]);
        string filename = args[1]; // Last argument, no exceptions!

        if (exists(filename)) {
            prescan(filename, cont);
        }
        else
        {
            import std.string : indexOf;
            bool glob =
                indexOf(filename, '*', 0) >= 0 || indexOf(filename, '?', 0) >= 0 ||
                indexOf(filename, '[', 0) >= 0 || indexOf(filename, ']', 0) >= 0;
            if (glob) { // No point to do globbing if there are no metacharacters
                import std.path : globMatch, dirName;
                debug writeln("GLOB ON");
                ShowingName = !ShowingName;
                int nbf;
                foreach (DirEntry dir; dirEntries(dirName(filename), SpanMode.shallow, cont))
                {
                    if (globMatch(dir.name, filename)) {
                        ++nbf;
                        prescan(dir.name, cont);
                    }
                }
                if (!nbf)
                {
                    ShowingName = false;
                    goto F_NE;
                }
            }
            else // No glob!
            {
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
