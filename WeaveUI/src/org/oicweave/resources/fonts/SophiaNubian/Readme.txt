README
Sophia Nubian Release 1.0
13 October 2008
========================

Thank you for your interest in the Sophia Nubian fonts.
We hope you find them useful!

Sophia Nubian is a sans serif, Unicode-compliant font based on the SIL
Sophia (similar to Univers) typeface. Its primary purpose is to
provide adequate representation for Nubian languages which use the
Coptic Unicode character set. Since Nubian languages do not use
casing, uppercase characters are not included in this font. A basic
set of Latin glyphs is also provided.

Sophia Nubian is released under the SIL Open Font License.
Sophia is a trademark of SIL International.
	
See the OFL and OFL-FAQ for details of the SIL Open Font License.
See the FONTLOG for information on this and previous releases.

TIPS:

We cannot afford to offer free technical support. The font has,
however, been through some testing and shown to work on
Windows XP and Windows Vista.

If you do find a problem, please do report it to
<fonts AT sil DOT org>.
We can't guarantee any direct response, but will try to fix reported
bugs in future versions.

Many problems can be solved, or at least explained, through an
understanding of the encoding and use of the fonts.
Here are some basic hints:

Encoding:
The fonts are encoded according to Unicode, so your application must
support Unicode text in order to access letters other than the
standard alphabet. Most Windows applications provide basic Unicode
support. You will, however, need some way of entering Unicode text
into your document.

The Unicode codepoints for the macrons are: U+0304 (used for a "short"
macron over a Nubian character) and U+0305 (used for the long macrons
over "u"). A short macron over the "a" vowel thus has two codepoints
(U+2C81 U+0304) and a long macron over the "u" vowel has four
codepoints (U+2C9F U+0305 U+2CA9 U+0305).

This font does not contain any uppercase characters in the Coptic
range. This is because Nubian languages do not use "casing." If your
word processor attempts to capitalize any Nubian characters, you may
get square boxes. The solution to this problem is to turn off any
"auto" rules for capitalization in your word processor.

The "u" vowel in Nubian is made up of two Unicode characters (U+2C9F
U+2CA9). When next to each other, these characters are closer together
than normal. In Microsoft Word, the characters may not always appear
close enough together. It appears to work properly in other
applications such as Toolbox, Notepad, OpenOffice or Microsoft
Publisher.

Keyboarding:
A Keyman keyboard is provided for typing in Nubian text.

Rendering:
This font is designed to work with any of two advanced font
technologies, Graphite or OpenType. To take advantage of the advanced
typographic capabilities of this font, you must be using applications
that provide an adequate level of support for Graphite or OpenType.

In particular, Nubian characters with a macron over them may not form
properly if your computer does not have a new version of Uniscribe.
For example, in Word 2000 the Nubian characters may not form properly.
The solution to this is to upgrade your version of Uniscribe
(usp10.dll). The minimum version of Uniscribe that will work is
1.420.2600.2180. In Word 2000 you would need to get an appropriate 
version of uniscribe and place it in this folder: 
C:\Program Files\Common Files\Microsoft Shared\Office10.

Nubian characters with a macron over it are not "composite" characters
(in Unicode). That means if you try to move cursor arrow forward or
backward over a character with a macron you will have to move the
cursor two times to go over the macron and the base character. It also
means that when you try to backspace over the character, you may end
up having to backspace twice.

Sometimes characters may not display perfectly on the screen, but they
display better when printed. We have attempted to address the most
severe issues, but we are certain there will still be some display
problems.

INSTALLATION AND CONFIGURATION
==============================

In Windows XP, open the Fonts control panel (Start, Control Panel,
Appearance and Themes, then look in the upper left). Then drag the
font files into the window - or choose File, Install New Font...,
and navigate to the files.


CONTACT
========
For more information please visit the Sophia Nubian page on SIL
International's Computers and Writing systems website:
http://scripts.sil.org/SophiaNubian

Or send an email to <fonts AT sil DOT org>

