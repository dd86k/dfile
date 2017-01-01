# dfile - Simple file scanner

dfile is a simple file scanner that is very similar to the UNIX `file` utility. It scans the file for a signature and will try to tell the nature of the file. I thought of making this as a native alternative mostly for Windows and adding some details here and there.

Mostly lazy with a lot of formats, but don't be shy to request formats.

## Examples
```
D:\DOCUMENTS\D projects\dfile>dfile tests\dfile
tests\dfile: ELF64 Executable file for x86-64 (Little-endian) systems

D:\DOCUMENTS\D projects\dfile>dfile tests\dfile.exe
tests\dfile.exe: PE32 (CUI) Windows Executable (EXE) for x86 systems

D:\DOCUMENTS\D projects\dfile>dfile tests\flourish.mid
tests\flourish.mid: MIDI file
```