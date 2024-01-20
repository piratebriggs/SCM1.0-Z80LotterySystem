Small Computer Monitor source, hex files, documentation, etc
============================================================

Folder "Apps"

This folder contains source and hex files for SCMonitor Apps.

SCMonitor Apps are programs that are written to work with SCMonitor.

These programs can be downloaded into memory and executed, or can be 
included in a ROM using SCMonitor's ROM filing system.


Folder "Builds"

Hex files containing various compiled SCMonitor builds.

If you simply want to program a ROM for your retro system you just need
the appropriate file from this folder.


Folder "Documentation"

SCMonitor installation, tutorial, user guide, reference sheet.


Folder "Source"

Source code for SCMonitor


Modifying and extending SCMonitor
=================================

Hopefully the folder layout and file organisation will make most things 
relatively easy to work out.

If you wish to make a completely new fork of this design, that's ok, but 
you risk being left out of new developments in the standard version. Best 
to only make changes in designated ways, if possible. That way it should 
be easier to integrate them in to future releases of SCMonitor.

Try to avoid changes to files other than:
*  File "!Main.asm" in the foler "SCMonitor\Source", and
*  Files in the folder "SCMonitor\Source\Hardware\Custom", and
*  Files in a folder you create in "SCMonitor\Source\Hardware"

Changing any other files will make it more difficult to port your code
to any new releases of SCMonitor.

To create a custom version of an existing build or to support a new class
of hardware, make a copy of an existing folder in "SCMonitor\Source\Hardware"

Modify the file "!main.asm" in the foler "SCMonitor\Source" to point to
your new hardware folder. This should be done by creating a new configuration
code such as "05" or "F9" and creating an "include" near the end of the file.
To avoid conflicts with configuration codes, use codes starting with "0" for
your own personal use, as shown in the example build configuration "00", or 
ask me to allocate a configuration code if you intend releasing your design.

Modify the contents of your new hardware folder as required to support your
application.

It is quite likely that 100% compatibility will not be achieved in future
releases of SCMonitor, so it may not be as easy as claimed to move your 
modifications to the next version. Such if life :-)
