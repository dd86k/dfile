module s_mach;

import std.stdio;
import dfile;

private const uint CPU_SUBTYPE_MASK = 0xFF00_0000;

private struct mach_header
{ // 64bit version just adds a reserved field
    uint magic;        /* mach magic number identifier */
    cpu_type_t cputype;    /* cpu specifier */
    int/*cpu_subtype_t*/ cpusubtype;    /* machine specifier */
    filetype_t filetype;    /* type of file */
    uint ncmds;        /* number of load commands */
    uint sizeofcmds;    /* the size of all the load commands */
    uint flags;        /* flags */
};

private enum cpu_type_t // int
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

private enum filetype_t
{
    MH_OBJECT      = 0x1,
    MH_EXECUTE     = 0x2,
    MH_FVMLIB      = 0x3,
    MH_CORE        = 0x4,
    MH_PRELOAD     = 0x5,
    MH_DYLIB       = 0x6,
    MH_DYLINKER    = 0x7,
    MH_BUNDLE      = 0x8,
    MH_DYLIB_STUB  = 0x9,
    MH_DSYM        = 0xa,
    MH_KEXT_BUNDLE = 0xb,
}

static void scan_mach(File file)
{
    bool reverse;
    file.rewind();

    mach_header h;
    {
        import core.stdc.string;
        ubyte[mach_header.sizeof] buf;
        file.rawRead(buf);
        memcpy(&h, &buf, mach_header.sizeof);
    }

    writef("%s: Mach-O ", file.name);
}