# dfile - Simple File scanner

The "Hey, I could do this for Windows" syndrome.

dfile is a simple file scanner that was inspired by the UNIX `file` utility. It scans the file for a signature and will try to tell the nature of the file.

Don't be shy to request a file format or request more information from a file format!

### Examples
```
D:\DOCUMENTS\D projects\dfile>dfile tests\dfile
tests\dfile: ELF64 Executable file for x86-64 (Little-endian) systems

D:\DOCUMENTS\D projects\dfile>dfile tests\dfile.exe
tests\dfile.exe: PE32 (CUI) Windows Executable (EXE) for x86 systems

D:\DOCUMENTS\D projects\dfile>dfile tests\flourish.mid
tests\flourish.mid: MIDI file
```