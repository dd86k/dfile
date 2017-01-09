module s_mach;

import std.stdio;
import dfile;

/*
 * Mach-O format scanner
 */

private const uint CPU_SUBTYPE_MASK = 0xFF00_0000;

private struct mach_header
{ // 64bit version just adds a reserved field
    uint magic;        /* mach magic number identifier */
    cpu_type_t cputype;    /* cpu specifier */
    uint/*cpu_subtype_t*/ cpusubtype;    /* machine specifier */
    filetype_t filetype;    /* type of file */
    uint ncmds;        /* number of load commands */
    uint sizeofcmds;    /* the size of all the load commands */
    flag_t flags;        /* flags */
}

private struct fat_header
{
    uint magic;
    uint nfat_arch;
}

private struct fat_arch
{
    cpu_type_t cputype;
    uint cpusubtype;
    uint offset;
    uint size;
    uint _align;
}

private enum cpu_type_t : uint
{
    ANY = 0xFFFF_FFFF,
    VAX = 1,
    ROMP = 2,
    NS32032 = 4,
    NS32332 = 5,
    MC680x0 = 6,
    I386 = 7,
    X86_64 = I386 | ABI64,
    MIPS = 8,
    NS32532 = 9,
    HPPA = 11,
    ARM = 12,
    MC88000 = 13,
    SPARC = 14,
    I860 = 15, // MSB
    I860_LITTLE = 16, // LSB
    RS6000 = 17,
    MC98000 = 18,
    POWERPC = 19,
    ABI64 = 0x1000000,
    POWERPC64 = POWERPC | ABI64,
    VEO = 255
}

// =============================
// cpu_subtype_t - CPU Subtypes, int
// =============================

private enum {
    CPU_SUBTYPE_MULTIPLE = 0xFFFF_FFFF
}

// VAX subtypes
private enum SUBTYPE_VAX
{
    VAX_ALL = 0,
    VAX780 = 1,
    VAX785 = 2,
    VAX750 = 3,
    VAX730 = 4,
    UVAXI = 5,
    UVAXII = 6,
    VAX8200 = 7,
    VAX8500 = 8,
    VAX8600 = 9,
    VAX8650 = 10,
    VAX8800 = 11,
    UVAXIII = 12
}

// ROMP subtypes
private enum SUBTYPE_ROMP
{
    RT_ALL = 0,
    RT_PC = 1,
    RT_APC = 2,
    RT_135 = 3
}

// 32032/32332/32532 subtypes
private enum SUBTYPE_32032
{
    MMAX_ALL = 0,
    MMAX_DPC = 1, /* 032 CPU */
    SQT = 2,
    MMAX_APC_FPU = 3, /* 32081 FPU */
    MMAX_APC_FPA = 4, /* Weitek FPA */
    MMAX_XPC = 5, /* 532 CPU */
}

// x86 subtypes
private enum SUBTYPE_I386
{
    I386_ALL = 3,
    X86_64_ALL = I386_ALL,
    _386 = 3,
    _486 = 4,
    _486SX = 4 + 128,
    _586 = 5,
    PENT = SUBTYPE_INTEL(5, 0),
    PENPRO = SUBTYPE_INTEL(6, 1),
    PENTII_M3 = SUBTYPE_INTEL(6, 3),
    PENTII_M5 = SUBTYPE_INTEL(6, 5),
    PENTIUM_4 = SUBTYPE_INTEL(10, 0),
}
int SUBTYPE_INTEL(short f, short m) { return f + (m << 4); }

// MIPS subtypes
private enum SUBTYPE_MIPS
{
    ALL = 0,
    R2300 = 1,
    R2600 = 2,
    R2800 = 3,
    R2800a = 4
}

// 680x0 subtypes (m68k)
private enum SUBTYPE_680x0
{
    MC680x0_ALL = 1,
    MC68030 = 1,
    MC68040 = 2,
    MC68030_ONLY = 3,
}

// HPPA subtypes
private enum SUBTYPE_HPPA
{
    ALL = 0,
    _7100 = 0,
    _7100LC = 1,
}

// Acorn subtypes
private enum SUBTYPE_ARM
{
    ALL = 0,
    A500_ARCH = 1,
    A500 = 2,
    A440 = 3,
    M4 = 4,
    V4T = 5,
    V6 = 6,
    V5TEJ = 7,
    XSCALE = 8,
    V7 = 9,
}

// MC88000 subtypes
private enum SUBTYPE_MC880000
{
    MC88000_ALL = 0,
    MMAX_JPC = 1,
    MC88100 = 1,
    MC88110 = 2,
}

// MC98000 (PowerPC) subtypes
private enum SUBTYPE_MC980000
{
    MC98000_ALL = 0,
    MC98601 = 1,
}

// I860 subtypes
private enum SUBTYPE_I860
{
    ALL = 0,
    _860 = 1,
}

// I860_LITTLE subtypes
private enum SUBTYPE_I860_LITTLE
{
    ALL = 0,
    LITTLE = 1
}

// RS6000 subtypes
private enum SUBTYPE_RS6000
{
    RS6000_ALL = 0,
    RS6000 = 1,
}

// Sun4 subtypes (port done at CMU (?))
private enum SUBTYPE_Sun4
{
    SUN4_ALL = 0,
    SUN4_260 = 1,
    SUN4_110 = 2,
}

// SPARC subtypes
private enum SUBTYPE_SPARC
{
    ALL = 0
}

// PowerPC subtypes
private enum SUBTYPE_PowerPC
{
    ALL	 = 0,
    _601 = 1,
    _602 = 2,
    _603 = 3,
    _603e = 4,
    _603ev = 5,
    _604 = 6,
    _604e = 7,
    _620 = 8,
    _750 = 9,
    _7400 = 10,
    _7450 = 11,
    _970 = 100,
}

// VEO subtypes
private enum SUBTYPE_VEO
{
    VEO_1 = 1,
    VEO_2 = 2,
    VEO_3 = 3,
    VEO_4 = 4,
    VEO_ALL = VEO_2,
}

//  =======================
/// File types
//  =======================
private enum filetype_t : uint
{
    Unknown        = 0,
    MH_OBJECT      = 0x1,
    MH_EXECUTE     = 0x2,
    MH_FVMLIB      = 0x3,
    MH_CORE        = 0x4,
    MH_PRELOAD     = 0x5,
    MH_DYLIB       = 0x6,
    MH_DYLINKER    = 0x7,
    MH_BUNDLE      = 0x8,
    MH_DYLIB_STUB  = 0x9,
    MH_DSYM        = 0xA,
    MH_KEXT_BUNDLE = 0xB,
}

private enum flag_t : uint
{
    MH_NOUNDEFS                = 0x00000001,
    MH_INCRLINK                = 0x00000002,
    MH_DYLDLINK                = 0x00000004,
    MH_BINDATLOAD              = 0x00000008,
    MH_PREBOUND                = 0x00000010,
    MH_SPLIT_SEGS              = 0x00000020,
    MH_LAZY_INIT               = 0x00000040,
    MH_TWOLEVEL                = 0x00000080,
    MH_FORCE_FLAT              = 0x00000100,
    MH_NOMULTIDEFS             = 0x00000200,
    MH_NOFIXPREBINDING         = 0x00000400,
    MH_PREBINDABLE             = 0x00000800,
    MH_ALLMODSBOUND            = 0x00001000,
    MH_SUBSECTIONS_VIA_SYMBOLS = 0x00002000,
    MH_CANONICAL               = 0x00004000,
    MH_WEAK_DEFINES            = 0x00008000,
    MH_BINDS_TO_WEAK           = 0x00010000,
    MH_ALLOW_STACK_EXECUTION   = 0x00020000,
    MH_ROOT_SAFE               = 0x00040000,
    MH_SETUID_SAFE             = 0x00080000,
    MH_NO_REEXPORTED_DYLIBS    = 0x00100000,
    MH_PIE                     = 0x00200000,
    MH_DEAD_STRIPPABLE_DYLIB   = 0x00400000,
    MH_HAS_TLV_DESCRIPTORS     = 0x00800000,
    MH_NO_HEAP_EXECUTION       = 0x01000000,
    MH_APP_EXTENSION_SAFE      = 0x02000000
}

private enum cmd_t : uint // Reserved for future use
{
    LC_SEGMENT              = 0x00000001,
    LC_SYMTAB               = 0x00000002,
    LC_SYMSEG               = 0x00000003,
    LC_THREAD               = 0x00000004,
    LC_UNIXTHREAD           = 0x00000005,
    LC_LOADFVMLIB           = 0x00000006,
    LC_IDFVMLIB             = 0x00000007,
    LC_IDENT                = 0x00000008,
    LC_FVMFILE              = 0x00000009,
    LC_PREPAGE              = 0x0000000A,
    LC_DYSYMTAB             = 0x0000000B,
    LC_LOAD_DYLIB           = 0x0000000C,
    LC_ID_DYLIB             = 0x0000000D,
    LC_LOAD_DYLINKER        = 0x0000000E,
    LC_ID_DYLINKER          = 0x0000000F,
    LC_PREBOUND_DYLIB       = 0x00000010,
    LC_ROUTINES             = 0x00000011,
    LC_SUB_FRAMEWORK        = 0x00000012,
    LC_SUB_UMBRELLA         = 0x00000013,
    LC_SUB_CLIENT           = 0x00000014,
    LC_SUB_LIBRARY          = 0x00000015,
    LC_TWOLEVEL_HINTS       = 0x00000016,
    LC_PREBIND_CKSUM        = 0x00000017,
    LC_LOAD_WEAK_DYLIB      = 0x80000018,
    LC_SEGMENT_64           = 0x00000019,
    LC_ROUTINES_64          = 0x0000001A,
    LC_UUID                 = 0x0000001B,
    LC_RPATH                = 0x8000001C,
    LC_CODE_SIGNATURE       = 0x0000001D,
    LC_SEGMENT_SPLIT_INFO   = 0x0000001E,
    LC_REEXPORT_DYLIB       = 0x8000001F,
    LC_LAZY_LOAD_DYLIB      = 0x00000020,
    LC_ENCRYPTION_INFO      = 0x00000021,
    LC_DYLD_INFO            = 0x00000022,
    LC_DYLD_INFO_ONLY       = 0x80000022,
    LC_LOAD_UPWARD_DYLIB    = 0x80000023,
    LC_VERSION_MIN_MACOSX   = 0x00000024,
    LC_VERSION_MIN_IPHONEOS = 0x00000025,
    LC_FUNCTION_STARTS      = 0x00000026,
    LC_DYLD_ENVIRONMENT     = 0x00000027,
    LC_MAIN                 = 0x80000028,
    LC_DATA_IN_CODE         = 0x00000029,
    LC_SOURCE_VERSION       = 0x0000002A,
    LC_DYLIB_CODE_SIGN_DRS  = 0x0000002B,
    LC_ENCRYPTION_INFO_64   = 0x0000002C,
    LC_LINKER_OPTION        = 0x0000002D,
    LC_LINKER_OPTIMIZATION_HINT = 0x0000002E,
    LC_VERSION_MIN_TVOS     = 0x0000002F,
    LC_VERSION_MIN_WATCHOS  = 0x00000030,
}

enum : uint
{
    MH_MAGIC =    0xFEEDFACE,
    MH_MAGIC_64 = 0xFEEDFACF,
    MH_CIGAM =    0xCEFAEDFE,
    MH_CIGAM_64 = 0xCFFAEDFE,
    FAT_MAGIC =   0xCAFEBABE,
    FAT_CIGAM =   0xBEBAFECA
}

private uint reverse(uint t)
{
    ubyte* pt = cast(ubyte*)&t;
    return (pt[0] | pt[1] << 8 | pt[2] << 16 | pt[3] << 24);
}

static void scan_mach(File file)
{
    bool reversed, fat;

    uint sig;
    {
        uint[1] b;
        file.rewind();
        file.rawRead(b);
        file.rewind();
        sig = b[0];
    }

    filetype_t filetype;
    cpu_type_t cpu_type;
    uint cpu_subtype;

    writef("%s: Mach-O ", file.name);

    final switch (sig)
    {
        case MH_MAGIC:
            write("32-bit");
            break;
        case MH_MAGIC_64:
            write("64-bit");
            break;
        case MH_CIGAM:
            write("Reversed 32-bit");
            reversed = true;
            break;
        case MH_CIGAM_64:
            write("Reversed 64-bit");
            reversed = true;
            break;
        case FAT_MAGIC:
            write("Fat");
            fat = true;
            break;
        case FAT_CIGAM:
            write("Reversed Fat");
            reversed = true;
            fat = true;
            break;
    }

    if (fat) // Java prefers Fat files
    {
        fat_header fh;
        {
            import core.stdc.string;
            ubyte[fat_header.sizeof] buf;
            file.rawRead(buf);
            memcpy(&fh, &buf, fat_header.sizeof);
        }

        if (fh.nfat_arch)
        {
            fat_arch fa;
            {
                import core.stdc.string;
                ubyte[fat_arch.sizeof] buf;
                file.rawRead(buf);
                memcpy(&fa, &buf, fat_arch.sizeof);
            }
            if (reversed)
            {
                cpu_type = cast(cpu_type_t)reverse(fa.cputype);
                cpu_subtype = reverse(fa.cpusubtype);
            }
            else
            {
                cpu_type = fa.cputype;
                cpu_subtype = fa.cpusubtype;
            }
        }
        else
        {
            writeln(" binary file");
            return;
        }
    }
    else
    {
        mach_header mh;
        {
            import core.stdc.string;
            ubyte[mach_header.sizeof] buf;
            file.rawRead(buf);
            memcpy(&mh, &buf, mach_header.sizeof);
        }
        if (reversed)
        {
            filetype = cast(filetype_t)reverse(mh.filetype);
            cpu_type = cast(cpu_type_t)reverse(mh.cputype);
            cpu_subtype = reverse(mh.cpusubtype);
        }
        else
        {
            filetype = mh.filetype;
            cpu_type = mh.cputype;
            cpu_subtype = mh.cpusubtype;
        }

        if (_debug)
        {
            writefln("%08X -> %08X", mh.filetype, filetype);
        }
    }

    if (!fat)
        write(' ');

    switch (filetype)
    {
        default: // Fat files have no filetypes.
            if (!fat)
                write("Unknown");
            break;
        case filetype_t.MH_OBJECT:
            write("Object file");
            break;
        case filetype_t.MH_EXECUTE:
            write("Executable file");
            break;
        case filetype_t.MH_FVMLIB:
            write("FVMLIB");
            break;
        case filetype_t.MH_CORE:
            write("Core file");
            break;
        case filetype_t.MH_PRELOAD:
            write("Preload file");
            break;
        case filetype_t.MH_DYLIB:
            write("Dynamic library file");
            break;
        case filetype_t.MH_DYLINKER:
            write("Dynamic linker file");
            break;
        case filetype_t.MH_BUNDLE:
            write("Bundle file");
            break;
        case filetype_t.MH_DYLIB_STUB:
            write("Dynamic library stub file");
            break;
        case filetype_t.MH_DSYM:
            write("DSYM file");
            break;
        case filetype_t.MH_KEXT_BUNDLE:
            write("Kext bundle file");
            break;
    }

    writefln(" for %s CPUs", cpu_type);
}