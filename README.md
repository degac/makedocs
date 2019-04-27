# makedocs
MakeDocs for BlitzMax (1.4)

This is a revision of MakeDocs for BlitzMax

I've added some features I think are needed

1. support for many example for any single command/function
2. exclusion of some MOD to be scanned (as they are useless to be documented or too slow to do it)
3. support for external command to be highlighted (without messing with source code)
4. support for some CMD commands like -help or -version

example usage:

MakeDocs -help (or -h)

MakeDocs -version

MakeDocs -exclude=Module1.mod,Module2.mod

MakeDocs -extern=file_path.txt (to add new commands to highlight)


(C) copyrights

Original source code written by BRL / Mark Sibly
