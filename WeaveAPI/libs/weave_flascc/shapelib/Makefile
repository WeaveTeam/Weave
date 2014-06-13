
all: check
	@echo "-------- shapelib --------"
	@echo "-> Generate SWIG wrappers around the functions in the library"
	"$(FLASCC)/usr/bin/swig" -as3 -module ShapeLib -outdir . -includeall -ignoremissing -o ShapeLib_wrapper.c swig.i

	@echo "-> Compile the SWIG wrapper to ABC"
	$(AS3COMPILERARGS) -abcfuture -AS3 -import $(call nativepath,$(FLASCC)/usr/lib/builtin.abc) -import $(call nativepath,$(FLASCC)/usr/lib/playerglobal.abc) ShapeLib.as
	# rename the output so the compiler doesn't accidentally use both this .as file along with the .abc file we just produced
	mv ShapeLib.as ShapeLib.as3

	@echo "-> Compile the library into a SWC"
	"$(FLASCC)/usr/bin/gcc" $(BASE_CFLAGS) ShapeLib.abc ShapeLib_wrapper.c source/*.c -emit-swc=sample.ShapeLib -o ShapeLib.swc

include Makefile.common

clean:
	rm -f *_wrapper.c *.swf *.swc *.as3 *.abc
