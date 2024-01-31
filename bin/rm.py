#! /user/bin/env python3

"""
This is a script to be used in place of the 'rm' command and leverage the
concept of Trash (Windows Recycling bin) so that files and directories
aren't deleted but moved to a specific location and can be recovered or 
perminantly deleted later.   For now this will leverage the Trash
feature in Ubuntu but could be made to be completely standalone with the
recovery capabilties later with another script.

To use this in your environment simply alias rm to this script in your
bashrc file or where you keep aliases.  i.e.

alias rm='~/bin/rm.py'
