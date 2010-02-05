#!/usr/bin/python
import sys

def gftp_descramble_password(password):
    """gftp password descrambler
 
    This code has been released in the Public Domain by the original author.

    Original code found here:
    http://www.g-loaded.eu/2009/05/07/descramble-passwords-from-gftp-bookmarks-using-python/
 
    """
    if not password.startswith('$'):
        return password
    newpassword = []
    pwdparts = map(ord, password)
    for i in range(1, len(pwdparts), 2):
        if ((pwdparts[i] & 0xc3) != 0x41 or
            (pwdparts[i+1] & 0xc3) != 0x41):
            return password
        newpassword.append(chr(((pwdparts[i] & 0x3c) << 2) +
                               ((pwdparts[i+1] & 0x3c) >> 2)))
    return "".join(newpassword)

print "Here is your password: "
print gftp_descramble_password(sys.argv[1:][0])
