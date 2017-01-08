module s_pe;

import std.stdio;
import dfile;

/**
 * MZ/NE/LE/LX/PE32 File Scanner | __PE32
 */

struct PE_HEADER
{
    ubyte[4] Signature; // "PE\0\0"
    PE_MACHINE_TYPE Machine;
    ushort NumberOfSections;
    uint TimeDateStamp;
    uint PointerToSymbolTable;
    uint NumberOfSymbols;
    ushort SizeOfOptionalHeader;
    PE_CHARACTERISTIC_TYPE Characteristics;
}

/// https://msdn.microsoft.com/en-us/library/windows/desktop/ms680339(v=vs.85).aspx
struct PE_OPTIONAL_HEADER
{
    PE_FORMAT Format;
    byte MajorLinkerVersion;
    byte MinorLinkerVersion;
    uint SizeOfCode;
    uint SizeOfInitializedData;
    uint SizeOfUninitializedData;
    uint AddressOfEntryPoint;
    uint BaseOfCode;
    uint BaseOfData;
    uint ImageBase;
    uint SectionAlignment;
    uint FileAlignment;
    ushort MajorOperatingSystemVersion;
    ushort MinorOperatingSystemVersion;
    ushort MajorImageVersion;
    ushort MinorImageVersion;
    ushort MajorSubsystemVersion;
    ushort MinorSubsystemVersion;
    uint Win32VersionValue;
    uint SizeOfImage;
    uint SizeOfHeaders;
    uint CheckSum;
    PE32_SUBSYSTEM Subsystem;
    ushort DllCharacteristics;
    uint SizeOfStackReserve;
    uint SizeOfStackCommit;
    uint SizeOfHeapReserve;
    uint SizeOfHeapCommit;
    uint LoaderFlags; // Obsolete
    uint NumberOfRvaAndSizes;
}

struct IMAGE_DATA_DIRECTORY
{ // Make it a Steam bundle!
    uint ExportTable;
    uint ExportTableSize;
    uint ImportTable;
    uint ImportTableSize;
    uint ResourceTable;
    uint ResourceTableSize;
    uint ExceptionTable;
    uint ExceptionTableSize;
    uint CertificateTable;
    uint CertificateTableSize;
    uint BaseRelocationTable;
    uint BaseRelocationTableSize;
    uint DebuggingInformation;
    uint DebuggingInformationSize;
    uint ArchitectureData;
    uint ArchitectureDataSize;
    ulong GlobalRegister;
    uint TLSTable;
    uint TLSTableSize;
    uint LoadConfigurationTable;
    uint LoadConfigurationTableSize;
    uint BoundImportTable;
    uint BoundImportTableSize;
    uint ImportAddressTable;
    uint ImportAddressTableSize;
    uint DelayImport;
    uint DelayImportTable;
    uint CLRHeader;
    uint CLRHeaderSize;
    uint Reserved;
    uint ReservedSize;
}

enum PE_MACHINE_TYPE : ushort
{
    UNKNOWN = 0x0,
    AM33 = 0x1d3,
    AMD64 = 0x8664,
    ARM = 0x1c0,
    ARMNT = 0x1c4,
    ARM64 = 0xaa64,
    EBC = 0xebc,
    I386 = 0x14c,
    IA64 = 0x200,
    M32R = 0x9041,
    MIPS16 = 0x266,
    MIPSFPU = 0x366,
    MIPSFPU16 = 0x466,
    POWERPC = 0x1f0,
    POWERPCFP = 0x1f1,
    R4000 = 0x166,
    SH3 = 0x1a2,
    SH3DSP = 0x1a3,
    SH4 = 0x1a6,
    SH5 = 0x1a8,
    THUMB = 0x1c2,
    WCEMIPSV2 = 0x169
}

enum PE_CHARACTERISTIC_TYPE : ushort
{
    RELOCS_STRIPPED = 0x0001,
    EXECUTABLE_IMAGE = 0x0002,
    LINE_NUMS_STRIPPED = 0x0004,
    LOCAL_SYMS_STRIPPED = 0x0008,
    AGGRESSIVE_WS_TRIM = 0x0010,
    LARGE_ADDRESS_AWARE = 0x0020,
    _16BIT_MACHINE = 0x0040,
    BYTES_REVERSED_LO = 0x0080,
    _32BIT_MACHINE = 0x0100,
    DEBUG_STRIPPED = 0x0200,
    REMOVABLE_RUN_FROM_SWAP = 0x0400,
    SYSTEM = 0x1000,
    DLL = 0x2000,
    UP_SYSTEM_ONLY = 0x4000,
    BYTES_REVERSED_HI = 0x8000
}

enum PE_FORMAT : short
{
    ROM   = 0x0107,
    HDR32 = 0x010B,
    HDR64 = 0x020B
}

enum PE32_SUBSYSTEM : ushort
{
    UNKNOWN = 0,
    NATIVE = 1,
    WINDOWS_GUI = 2,
    WINDOWS_CUI = 3,
    OS2_CUI = 5,
    POSIX_CUI = 7,
    WINDOWS_CE_GUI = 9,
    EFI_APPLICATION = 10,
    EFI_BOOT_SERVICE_DRIVER = 11,
    EFI_RUNTIME_DRIVER = 12,
    EFI_ROM = 13,
    XBOX = 14,
    WINDOWS_BOOT_APPLICATION = 16
}

static void scan_pe(File file)
{
    PE_HEADER peh; // PE32
    PE_OPTIONAL_HEADER peoh;
    IMAGE_DATA_DIRECTORY dirs;
    { // GC
        import core.stdc.string;

        {
            ubyte[PE_HEADER.sizeof] buf;
            file.rawRead(buf);
            memcpy(&peh, &buf, peh.sizeof);
        }

        if (peh.SizeOfOptionalHeader > 0)
        { // PE Optional Header
            ubyte[PE_OPTIONAL_HEADER.sizeof] buf;
            file.rawRead(buf);
            memcpy(&peoh, &buf, peoh.sizeof);
        }

        {
            ubyte[IMAGE_DATA_DIRECTORY.sizeof] buf;
            file.rawRead(buf);
            memcpy(&dirs, &buf, dirs.sizeof);
        }

        /*if (_debug)
        {
            writef("L%04d: Buffer : ", __LINE__);
            foreach (i; b)
                writef("%04X ", i);
            writeln();
        }*/
    }

    if (_more || _debug)
    {
        writefln("Machine type : %s", peh.Machine);
        writefln("Number of sections : %s", peh.NumberOfSymbols);
        writefln("Time stamp : %s", peh.TimeDateStamp);
        writefln("Pointer to Symbol Table : %s", peh.PointerToSymbolTable);
        writefln("Number of symbols : %s", peh.NumberOfSymbols);
        writefln("Size of Optional Header : %s", peh.SizeOfOptionalHeader);
        writefln("Characteristics : %Xh", peh.Characteristics);

        if (peh.SizeOfOptionalHeader > 0)
        {
            writefln("Format : %X", peoh.Format);
            writefln("Subsystem : %X", peoh.Subsystem);
        }
    }
    
    writef("%s: PE32", file.name);
    
    switch (peoh.Format)
    {
    case PE_FORMAT.ROM: // HDR
        write("-ROM ");
        break;
    case PE_FORMAT.HDR32:
        write(" ");
        break;
    case PE_FORMAT.HDR64:
        write("+ ");
        break;
    default:
        write(" (Format?) ");
        break;
    }

    switch (peoh.Subsystem)
    {
    default:
    case PE32_SUBSYSTEM.UNKNOWN:
        write("(Unknown)");
        break;

    case PE32_SUBSYSTEM.NATIVE:
        write("(Native)");
        break;

    case PE32_SUBSYSTEM.WINDOWS_GUI:
        write("(GUI)");
        break;

    case PE32_SUBSYSTEM.WINDOWS_CUI:
        write("(CUI)");
        break;

    case PE32_SUBSYSTEM.POSIX_CUI:
        write("(POSIX CUI)");
        break;

    case PE32_SUBSYSTEM.WINDOWS_CE_GUI:
        write("(CE GUI)");
        break;

    case PE32_SUBSYSTEM.EFI_APPLICATION :
        write("(EFI)");
        break;

    case PE32_SUBSYSTEM.EFI_BOOT_SERVICE_DRIVER :
        write("(EFI Boot Service driver)");
        break;

    case PE32_SUBSYSTEM.EFI_RUNTIME_DRIVER:
        write("(EFI Runtime driver)");
        break;

    case PE32_SUBSYSTEM.EFI_ROM:
        write("(EFI ROM)");
        break;

    case PE32_SUBSYSTEM.XBOX:
        write("(XBOX)");
        break;
    }

    write(" Windows ");

    if (dirs.CLRHeader && dirs.CLRHeaderSize)
        write(".NET ");
    
    if (peh.Characteristics & PE_CHARACTERISTIC_TYPE.EXECUTABLE_IMAGE)
        write("Executable file");
    else if (peh.Characteristics & PE_CHARACTERISTIC_TYPE.DLL)
        write("Library file");
    else
        write("Unknown");

    write(" for ");

    switch (peh.Machine)
    {
    default:
    case PE_MACHINE_TYPE.UNKNOWN:
        write("unknown");
        break;

    case PE_MACHINE_TYPE.AM33:
        write("Matsushita AM33");
        break;

    case PE_MACHINE_TYPE.AMD64:
        write("x86-64");
        break;

    case PE_MACHINE_TYPE.ARM:
        write("ARM (Little endian)");
        break;

    case PE_MACHINE_TYPE.ARMNT:
        write("ARMv7+ (Thumb mode)");
        break;

    case PE_MACHINE_TYPE.ARM64:
        write("ARMv8 (64-bit)");
        break;
        
    case PE_MACHINE_TYPE.EBC:
        write("EFI (Byte Code)");
        break;
        
    case PE_MACHINE_TYPE.I386:
        write("x86");
        break;
        
    case PE_MACHINE_TYPE.IA64:
        write("IA64");
        break;
        
    case PE_MACHINE_TYPE.M32R:
        write("Mitsubishi M32R (Little endian)");
        break;
        
    case PE_MACHINE_TYPE.MIPS16:
        write("MIPS16");
        break;
        
    case PE_MACHINE_TYPE.MIPSFPU:
        write("MIPS (w/FPU)");
        break;
        
    case PE_MACHINE_TYPE.MIPSFPU16:
        write("MIPS16 (w/FPU)");
        break;
        
    case PE_MACHINE_TYPE.POWERPC:
        write("PowerPC");
        break;
        
    case PE_MACHINE_TYPE.POWERPCFP:
        write("PowerPC (w/FPU)");
        break;

    case PE_MACHINE_TYPE.R4000:
        write("MIPS (Little endian)");
        break;
        
    case PE_MACHINE_TYPE.SH3:
        write("Hitachi SH3");
        break;
        
    case PE_MACHINE_TYPE.SH3DSP:
        write("Hitachi SH3 DSP");
        break;
        
    case PE_MACHINE_TYPE.SH4:
        write("Hitachi SH4");
        break;

    case PE_MACHINE_TYPE.SH5:
        write("Hitachi SH5");
        break;
        
    case PE_MACHINE_TYPE.THUMB:
        write(`ARM or Thumb ("interworking")`);
        break;
        
    case PE_MACHINE_TYPE.WCEMIPSV2:
        write("MIPS WCE v2 (Little endian)");
        break;
    }

    write(" systems");

    if (peh.Characteristics & PE_CHARACTERISTIC_TYPE.RELOCS_STRIPPED)
        write(", relocs stripped");

    if (peh.Characteristics & PE_CHARACTERISTIC_TYPE.LARGE_ADDRESS_AWARE)
        write(", large addresses aware");

    writeln();
}