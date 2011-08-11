# Microsoft Developer Studio Generated NMAKE File, Based on JtdsXA.dsp
!IF "$(CFG)" == ""
CFG=JtdsXA - Win32 Debug
!MESSAGE No configuration specified. Defaulting to JtdsXA - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "JtdsXA - Win32 Release" && "$(CFG)" != "JtdsXA - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "JtdsXA.mak" CFG="JtdsXA - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "JtdsXA - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "JtdsXA - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

!IF  "$(CFG)" == "JtdsXA - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release
# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

ALL : "$(OUTDIR)\JtdsXA.dll"


CLEAN :
	-@erase "$(INTDIR)\JtdsXA.obj"
	-@erase "$(INTDIR)\JtdsXA.res"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(OUTDIR)\JtdsXA.dll"
	-@erase "$(OUTDIR)\JtdsXA.exp"
	-@erase "$(OUTDIR)\JtdsXA.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MD /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "JTDSXA_EXPORTS" /Fp"$(INTDIR)\JtdsXA.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

MTL=midl.exe
MTL_PROJ=/nologo /D "NDEBUG" /mktyplib203 /win32 
RSC=rc.exe
RSC_PROJ=/l 0x809 /fo"$(INTDIR)\JtdsXA.res" /d "NDEBUG" 
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\JtdsXA.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=xaswitch.lib xolehlp.lib opends60.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /dll /incremental:no /pdb:"$(OUTDIR)\JtdsXA.pdb" /machine:I386 /out:"$(OUTDIR)\JtdsXA.dll" /implib:"$(OUTDIR)\JtdsXA.lib" 
LINK32_OBJS= \
	"$(INTDIR)\JtdsXA.obj" \
	"$(INTDIR)\JtdsXA.res"

"$(OUTDIR)\JtdsXA.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "JtdsXA - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug
# Begin Custom Macros
OutDir=.\Debug
# End Custom Macros

ALL : "$(OUTDIR)\JtdsXA.dll"


CLEAN :
	-@erase "$(INTDIR)\JtdsXA.obj"
	-@erase "$(INTDIR)\JtdsXA.res"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(OUTDIR)\JtdsXA.dll"
	-@erase "$(OUTDIR)\JtdsXA.exp"
	-@erase "$(OUTDIR)\JtdsXA.ilk"
	-@erase "$(OUTDIR)\JtdsXA.lib"
	-@erase "$(OUTDIR)\JtdsXA.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MDd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "JTDSXA_EXPORTS" /Fp"$(INTDIR)\JtdsXA.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

MTL=midl.exe
MTL_PROJ=/nologo /D "_DEBUG" /mktyplib203 /win32 
RSC=rc.exe
RSC_PROJ=/l 0x809 /fo"$(INTDIR)\JtdsXA.res" /d "_DEBUG" 
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\JtdsXA.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=xaswitch.lib xolehlp.lib opends60.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /dll /incremental:yes /pdb:"$(OUTDIR)\JtdsXA.pdb" /debug /machine:I386 /out:"$(OUTDIR)\JtdsXA.dll" /implib:"$(OUTDIR)\JtdsXA.lib" /pdbtype:sept 
LINK32_OBJS= \
	"$(INTDIR)\JtdsXA.obj" \
	"$(INTDIR)\JtdsXA.res"

"$(OUTDIR)\JtdsXA.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 


!IF "$(NO_EXTERNAL_DEPS)" != "1"
!IF EXISTS("JtdsXA.dep")
!INCLUDE "JtdsXA.dep"
!ELSE 
!MESSAGE Warning: cannot find "JtdsXA.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "JtdsXA - Win32 Release" || "$(CFG)" == "JtdsXA - Win32 Debug"
SOURCE=.\JtdsXA.c

!IF  "$(CFG)" == "JtdsXA - Win32 Release"

CPP_SWITCHES=/nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "JTDSXA_EXPORTS" /Fp"$(INTDIR)\JtdsXA.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 

"$(INTDIR)\JtdsXA.obj" : $(SOURCE) "$(INTDIR)"
	$(CPP) @<<
  $(CPP_SWITCHES) $(SOURCE)
<<


!ELSEIF  "$(CFG)" == "JtdsXA - Win32 Debug"

CPP_SWITCHES=/nologo /MTd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "JTDSXA_EXPORTS" /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 

"$(INTDIR)\JtdsXA.obj" : $(SOURCE) "$(INTDIR)"
	$(CPP) @<<
  $(CPP_SWITCHES) $(SOURCE)
<<


!ENDIF 

SOURCE=.\JtdsXA.rc

"$(INTDIR)\JtdsXA.res" : $(SOURCE) "$(INTDIR)"
	$(RSC) $(RSC_PROJ) $(SOURCE)



!ENDIF 

