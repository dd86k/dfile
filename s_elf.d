module s_elf;

import std.stdio;
import dfile;

/**
 * ELF format Scanner
 */

private const size_t EI_NIDENT = 16;
private struct Elf32_Ehdr
{
    public ubyte[EI_NIDENT] e_ident;
    public ELF_e_type e_type;
    public ELF_e_machine e_machine;
    public ELF_e_version e_version;
    public uint e_entry;
    public uint e_phoff;
    public uint e_shoff;
    public uint e_flags;
    public ushort e_ehsize;
    public ushort e_phentsize;
    public ushort e_phnum;
    public ushort e_shentsize;
    public ushort e_shnum;
    public ushort e_shstrndx;
}

private enum ELF_e_type : ushort
{
    ET_NONE = 0,        // No file type
    ET_REL = 1,         // Relocatable file
    ET_EXEC = 2,        // Executable file
    ET_DYN = 3,         // Shared object file
    ET_CORE = 4,        // Core file
    ET_LOPROC = 0xFF00, // Processor-specific
    ET_HIPROC = 0xFFFF  // Processor-specific
}

private enum ELF_e_machine : ushort
{
    EM_NONE = 0,  // No machine
    EM_M32 = 1,   // AT&T WE 32100
    EM_SPARC = 2, // SPARC
    EM_386 = 3,   // Intel Architecture
    EM_68K = 4,   // Motorola 68000
    EM_88K = 5,   // Motorola 88000
    EM_860 = 7,   // Intel 80860
    EM_MIPS = 8,  // MIPS RS3000
    EM_MIPS_RS4_BE = 10, // MIPS RS4000 Big-Endian
    // Rest is from http://wiki.osdev.org/ELF
    EM_POWERPC = 0x14,
    EM_ARM = 0x28,
    EM_SUPERH = 0xA2,
    EM_IA64 = 0x32,
    EM_AMD64 = 0x3E,
    EM_AARCH64 = 0xB7
}

private enum ELF_e_version : uint
{
    EV_NONE = 0,
    EV_CURRENT = 1
}

static void scan_elf(File file)
{
    if (_debug)
        writefln("L%04d: Started scanning ELF file", __LINE__);

    Elf32_Ehdr header;
    {
        ubyte[Elf32_Ehdr.sizeof] buf;
        file.rewind();
        file.rawRead(buf);

        byte* pbuf = cast(byte*)&buf, pheader = cast(byte*)&header;

        for (size_t i = 0; i < Elf32_Ehdr.sizeof; ++i)
            *(pheader + i) = *(pbuf + i);
    }

    if (_debug)
    {
        write("e_ident: ");
        foreach (c; header.e_ident)
            writef("%02X ", c);
        writeln();
    }

    if (_debug || _more)
    {
        writefln("type: %s", header.e_type);
        writefln("machine: %s", header.e_machine);
        writefln("version: %s", header.e_version);
        writefln("entry: %s", header.e_entry);
        writefln("phoff: %s", header.e_phoff);
        writefln("shoff: %s", header.e_shoff);
        writefln("flags: %s", header.e_flags);
        writefln("ehsize: %s", header.e_ehsize);
        writefln("phentsize: %s", header.e_phentsize);
        writefln("phnum: %s", header.e_phnum);
        writefln("shentsize: %s", header.e_shentsize);
        writefln("shnum: %s", header.e_shnum);
        writefln("shstrndx: %s", header.e_shstrndx);
    }

    writef("%s: ELF", file.name);

    switch (header.e_ident[4])
    {
    default: // Invalid class
        write(" (Invalid) ");
        break;
    case 1: // 32-bit objects
        write("32 ");
        break;
    case 2: // 64-bit objects
        write("64 ");
        break;
    }

    switch (header.e_type)
    {
    default:
    case ELF_e_type.ET_NONE:
        write("(No file type)");
        break;

    case ELF_e_type.ET_REL:
        write("Relocatable file");
        break;

    case ELF_e_type.ET_EXEC:
        write("Executable file");
        break;

    case ELF_e_type.ET_DYN:
        write("Shared object file");
        break;

    case ELF_e_type.ET_CORE:
        write("Core file");
        break;

    case ELF_e_type.ET_LOPROC:
    case ELF_e_type.ET_HIPROC:
        write("Professor-specific file");
        break;
    }

    write(" for ");

    switch (header.e_machine)
    {
    case ELF_e_machine.EM_NONE:
        write("no");
        break;
        
    case ELF_e_machine.EM_M32:
        write("AT&T WE 32100 (M32)");
        break;
        
    case ELF_e_machine.EM_SPARC:
        write("SPARC");
        break;
    
    case ELF_e_machine.EM_386:
        write("x86");
        break;
        
    case ELF_e_machine.EM_68K:
        write("Motorola 68000");
        break;
        
    case ELF_e_machine.EM_88K:
        write("Motorola 88000");
        break;
        
    case ELF_e_machine.EM_860:
        write("Intel 80860");
        break;
        
    case ELF_e_machine.EM_MIPS:
        write("MIPS RS3000");
        break;

    case ELF_e_machine.EM_POWERPC:
        write("PowerPC");
        break;

    case ELF_e_machine.EM_ARM:
        write("ARM");
        break;

    case ELF_e_machine.EM_SUPERH:
        write("SuperH");
        break;

    case ELF_e_machine.EM_IA64:
        write("IA64");
        break;

    case ELF_e_machine.EM_AMD64:
        write("x86-64");
        break;

    case ELF_e_machine.EM_AARCH64:
        write("AArch64");
        break;

    default:
        write("unknown");
        break;
    }

    write(" ");

    switch (header.e_ident[5])
    {
    default:
        write("(Invalid Endian)");
        break;
    case 1:
        write("(Little-endian)");
        break;
    case 2:
        write("(Big-endian)");
        break;
    }

    writeln(" systems");
}