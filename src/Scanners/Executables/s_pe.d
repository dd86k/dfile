/*
 * s_pe.d : PE32 format Scanner
 */

module s_pe;

import core.stdc.stdio;
import dfile : report, More, fp;

private struct PE_HEADER { align(1):
    char[2] Signature; // "PE\0\0"
    PE_MACHINE Machine;
    ushort NumberOfSections;
    uint TimeDateStamp;
    uint PointerToSymbolTable;
    uint NumberOfSymbols;
    ushort SizeOfOptionalHeader;
    PE_CHARACTERISTIC Characteristics;
}

/// https://msdn.microsoft.com/en-us/library/windows/desktop/ms680339(v=vs.85).aspx
private struct PE_OPTIONAL_HEADER { align(1):
    PE_FORMAT magic;
    ubyte MajorLinkerVersion;
    ubyte MinorLinkerVersion;
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
    PE_SUBSYSTEM Subsystem;
    ushort DllCharacteristics;
    uint SizeOfStackReserve;
    uint SizeOfStackCommit;
    uint SizeOfHeapReserve;
    uint SizeOfHeapCommit;
    uint LoaderFlags; // Obsolete
    uint NumberOfRvaAndSizes;
}

// IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16
private struct IMAGE_DATA_DIRECTORY { align(1):
    ulong ExportTable;
    ulong ImportTable;
    ulong ResourceTable;
    ulong ExceptionTable;
    ulong CertificateTable;
    ulong BaseRelocationTable;
    ulong DebugDirectory;
    ulong ArchitectureData;
    ulong GlobalPtr;
    ulong TLSTable;
    ulong LoadConfigurationTable;
    ulong BoundImportTable;
    ulong ImportAddressTable;
    ulong DelayImport;
    ulong CLRHeader;
    //ulong Reserved;
}

private enum PE_MACHINE : ushort
{
    UNKNOWN = 0,
    AM33 = 0x1d3,
    AMD64 = 0x8664,
    ARM = 0x1c0,
    ARMNT = 0x1c4,
    ARM64 = 0xaa64,
    EBC = 0xebc,
    I386 = 0x14c,
    IA64 = 0x200,
    M32R = 0x9041, // LE
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
    WCEMIPSV2 = 0x169,
    // https://en.wikibooks.org/wiki/X86_Disassembly/Windows_Executable_Files
    CLR = 0xC0EE,
}

private enum PE_CHARACTERISTIC : ushort
{
    RELOCS_STRIPPED = 0x0001,
    EXECUTABLE_IMAGE = 0x0002,
    LINE_NUMS_STRIPPED = 0x0004,
    LOCAL_SYMS_STRIPPED = 0x0008,
    AGGRESSIVE_WS_TRIM = 0x0010, // obsolete
    LARGE_ADDRESS_AWARE = 0x0020,
    _16BIT_MACHINE = 0x0040,
    BYTES_REVERSED_LO = 0x0080, // obsolete
    _32BIT_MACHINE = 0x0100,
    DEBUG_STRIPPED = 0x0200,
    REMOVABLE_RUN_FROM_SWAP = 0x0400,
    NET_RUN_FROM_SWAP = 0x0800,
    SYSTEM = 0x1000,
    DLL = 0x2000,
    UP_SYSTEM_ONLY = 0x4000,
    BYTES_REVERSED_HI = 0x8000 // obsolete
}

private enum PE_FORMAT : ushort
{
    ROM   = 0x0107,
    HDR32 = 0x010B,
    HDR64 = 0x020B
}

private enum PE_SUBSYSTEM : ushort
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

/// Scan a PE32 executable
void scan_pe() {
    PE_HEADER peh; // PE32
    PE_OPTIONAL_HEADER peoh;
    IMAGE_DATA_DIRECTORY dirs;
    fread(&peh, peh.sizeof, 1, fp);

    if (peh.SizeOfOptionalHeader > 0) { // PE Optional Header
        fread(&peoh, peoh.sizeof, 1, fp);
        if (peoh.magic == PE_FORMAT.HDR64)
            fseek(fp, 16, SEEK_CUR);
        fread(&dirs, dirs.sizeof, 1, fp);
    }

    report("PE32", false);

    switch (peoh.magic) {
    case PE_FORMAT.ROM: // HDR
        printf("-ROM ");
        break;
    case PE_FORMAT.HDR32:
        printf(" ");
        break;
    case PE_FORMAT.HDR64:
        printf("+ ");
        break;
    default:
        printf(" (Magic?) ");
        break;
    }

    switch (peoh.Subsystem) {
    default:
        printf("Unknown");
        break;
    case PE_SUBSYSTEM.NATIVE:
        printf("Native Windows");
        break;
    case PE_SUBSYSTEM.WINDOWS_GUI:
        printf("Windows GUI");
        break;
    case PE_SUBSYSTEM.WINDOWS_CUI:
        printf("Windows Console");
        break;
    case PE_SUBSYSTEM.POSIX_CUI:
        printf("Posix Console");
        break;
    case PE_SUBSYSTEM.WINDOWS_CE_GUI:
        printf("Windows CE GUI");
        break;
    case PE_SUBSYSTEM.EFI_APPLICATION :
        printf("EFI");
        break;
    case PE_SUBSYSTEM.EFI_BOOT_SERVICE_DRIVER :
        printf("EFI Boot Service driver");
        break;
    case PE_SUBSYSTEM.EFI_RUNTIME_DRIVER:
        printf("EFI Runtime driver");
        break;
    case PE_SUBSYSTEM.EFI_ROM:
        printf("EFI ROM");
        break;
    case PE_SUBSYSTEM.XBOX:
        printf("XBOX");
        break;
    case PE_SUBSYSTEM.WINDOWS_BOOT_APPLICATION:
        printf("Windows Boot Application");
        break;
    }

    if (dirs.CLRHeader)
        printf(" .NET");

    if (peh.Characteristics & PE_CHARACTERISTIC.DLL)
        printf(" Library");
    else if (peh.Characteristics & PE_CHARACTERISTIC.EXECUTABLE_IMAGE)
        printf(" Executable");
    else
        printf(" Unknown Type");

    printf(" for ");

    switch (peh.Machine) {
    default: // PE_MACHINE.UNKNOWN
        printf("Unknown");
        break;
    case PE_MACHINE.I386:
        printf("x86");
        break;
    case PE_MACHINE.AMD64:
        printf("x86-64");
        break;
    case PE_MACHINE.IA64:
        printf("IA64");
        break;
    case PE_MACHINE.EBC:
        printf("EFI (Byte Code)");
        break;
    case PE_MACHINE.CLR:
        printf("Common Language Runtime");
        break;
    case PE_MACHINE.ARM:
        printf("ARM (Little Endian)");
        break;
    case PE_MACHINE.ARMNT:
        printf("ARMv7+ (Thumb)");
        break;
    case PE_MACHINE.ARM64:
        printf("ARMv8 (64-bit)");
        break;
    case PE_MACHINE.M32R:
        printf("Mitsubishi M32R (Little endian)");
        break;
    case PE_MACHINE.AM33:
        printf("Matsushita AM33");
        break;
    case PE_MACHINE.MIPS16:
        printf("MIPS16");
        break;
    case PE_MACHINE.MIPSFPU:
        printf("MIPS (w/FPU)");
        break;
    case PE_MACHINE.MIPSFPU16:
        printf("MIPS16 (w/FPU)");
        break;
    case PE_MACHINE.POWERPC:
        printf("PowerPC");
        break;
    case PE_MACHINE.POWERPCFP:
        printf("PowerPC (w/FPU)");
        break;
    case PE_MACHINE.R4000:
        printf("MIPS (Little endian)");
        break;
    case PE_MACHINE.SH3:
        printf("Hitachi SH3");
        break;
    case PE_MACHINE.SH3DSP:
        printf("Hitachi SH3 DSP");
        break;
    case PE_MACHINE.SH4:
        printf("Hitachi SH4");
        break;
    case PE_MACHINE.SH5:
        printf("Hitachi SH5");
        break;
    case PE_MACHINE.THUMB:
        printf(`ARM or Thumb ("Interworking")`);
        break;
    case PE_MACHINE.WCEMIPSV2:
        printf("MIPS WCE v2 (Little Endian)");
        break;
    }

    printf(" machines");

    if (peh.Characteristics) {
        if (peh.Characteristics & PE_CHARACTERISTIC.RELOCS_STRIPPED)
            printf(", RELOCS_STRIPPED");
        if (peh.Characteristics & PE_CHARACTERISTIC.LINE_NUMS_STRIPPED)
            printf(", LINE_NUMS_STRIPPED");
        if (peh.Characteristics & PE_CHARACTERISTIC.LOCAL_SYMS_STRIPPED)
            printf(", LOCAL_SYMS_STRIPPED");
        if (peh.Characteristics & PE_CHARACTERISTIC.LARGE_ADDRESS_AWARE)
            printf(", LARGE_ADDRESS_AWARE");
        if (peh.Characteristics & PE_CHARACTERISTIC._16BIT_MACHINE)
            printf(", 16BIT_MACHINE");
        if (peh.Characteristics & PE_CHARACTERISTIC._32BIT_MACHINE)
            printf(", 32BIT_MACHINE");
        if (peh.Characteristics & PE_CHARACTERISTIC.DEBUG_STRIPPED)
            printf(", DEBUG_STRIPPED");
        if (peh.Characteristics & PE_CHARACTERISTIC.REMOVABLE_RUN_FROM_SWAP)
            printf(", REMOVABLE_RUN_FROM_SWAP");
        if (peh.Characteristics & PE_CHARACTERISTIC.NET_RUN_FROM_SWAP)
            printf(", NET_RUN_FROM_SWAP");
        if (peh.Characteristics & PE_CHARACTERISTIC.SYSTEM)
            printf(", SYSTEM");
        if (peh.Characteristics & PE_CHARACTERISTIC.UP_SYSTEM_ONLY)
            printf(", UP_SYSTEM_ONLY");
    }

    printf("\n");

    if (More) {
        printf("Machine type : %Xh\n", peh.Machine);
        printf("Number of sections : %Xh\n", peh.NumberOfSymbols);
        printf("Time stamp : %Xh\n", peh.TimeDateStamp);
        printf("Pointer to Symbol Table : %Xh\n", peh.PointerToSymbolTable);
        printf("Number of symbols : %Xh\n", peh.NumberOfSymbols);
        printf("Size of Optional Header : %Xh\n", peh.SizeOfOptionalHeader);
        printf("Characteristics : %Xh\n", peh.Characteristics);

        if (peh.SizeOfOptionalHeader > 0) {
            printf("Format    : %Xh\n", peoh.magic);
            printf("Subsystem : %Xh\n", peoh.Subsystem);
            printf("CLR Header: %Xh\n", dirs.CLRHeader);
        }
    }
}