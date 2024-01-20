CP/M PutSys Plus

This project creates a version of CP/M PutSys with the CP/M BDOS and CBIOS hex 
files embedded in it, for LiNC80 and RC2014 systems.

This results in a single hex file to download via a terminal, rather 
than three separate files. So it is much more convenient.

This is Grant Searle's code, modified for use with Small Computer Workshop IDE
and with CP/M hex files embedded in it.

Compile options for LiNC80 and RC2014 systems.

Filename format: 
"PutSys_<product-name>_<serial-device>_<storage-device>_<code-start-address>"

Once the hex file has been sent to the target hardware from the terminal 
software, it can be run with the command "G <code-start-address>". 
eg. "G 8000"

SCC 2018-04-13


NOTE: 
Some memory locations may be overwritten when HEX files are inserted.
If a warning is given about this it is ok to ignore it.
