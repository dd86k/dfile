# dfile - Simple file scanner

dfile is a simple file scanner that is very similar to the UNIX `file` utility.

Don't be shy to request more formats or format scans (e.g. PE32 gives more details)!

It currently recognizes quite a few signatures.

It tells more details of:
- Game files
  - PWAD/IWAD
  - GTA Text files
  - RPF GTA archives

It does a detailed scan of:
- Exectuable files
  - MZ (MS-DOS) (TODO)
  - LE/LX (OS/2)
  - NE (Windows 3.x)
  - PE32 (Win32)
  - ELF (POSIX)
  - Mach-O (macOS) (Incomplete)