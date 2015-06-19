FLASCC:=/cygdrive/c/flascc/sdk
FLEX:=/cygdrive/c/flex
AS3COMPILER:=asc2.jar
BASE_CFLAGS:=-Werror -Wno-write-strings -Wno-trigraphs
C_OBJS =strftime2.o strptime2.o timelocal.o b64util.o dateutil.o hashutil.o main.o modp_b64.o ziputil.o kdtree.o as3-kdtree.o
CPP_OBJS = CSVParser.oo
$?UNAME=$(shell uname -s)
ifneq (,$(findstring CYGWIN,$(UNAME)))
	$?nativepath=$(shell cygpath -at mixed $(1))
	$?unixpath=$(shell cygpath -at unix $(1))
else
	$?nativepath=$(abspath $(1))
	$?unixpath=$(abspath $(1))
endif

ifneq (,$(findstring "asc2.jar","$(AS3COMPILER)"))
	$?AS3COMPILERARGS=java $(JVMARGS) -jar $(call nativepath,$(FLASCC)/usr/lib/$(AS3COMPILER)) -merge -md 
else
	echo "ASC is no longer supported" ; exit 1 ;
endif

all: check weave_flascc.swc

check:
	@if [ -d $(FLASCC)/usr/bin ] ; then true ; \
	else echo "Couldn't locate FLASCC sdk directory, please invoke make with \"make FLASCC=/path/to/FLASCC/sdk ...\"" ; exit 1 ; \
	fi

	@if [ -d "$(FLEX)/bin" ] ; then true ; \
	else echo "Couldn't locate Flex sdk directory, please invoke make with \"make FLEX=/path/to/flex  ...\"" ; exit 1 ; \
	fi
timetest: $(C_OBJS) timetest.o
	"$(FLASCC)/usr/bin/gcc" $(BASE_CFLAGS) -O4 $^ -o $@
%.o: weave_flascc/%.c
	"$(FLASCC)/usr/bin/gcc" $(BASE_CFLAGS) -std=c99 -O4 -c $? -o $@
%.oo: weave_flascc/%.cpp
	"$(FLASCC)/usr/bin/g++" $(BASE_CFLAGS) -O4 -c $? -o $@
weave_flascc.swc: $(C_OBJS) $(CPP_OBJS)
	"$(FLASCC)/usr/bin/g++" $(BASE_CFLAGS) -O4 -flto-api=weave_flascc/exports.txt $^ -emit-swc=weave.flascc -o $@
#weave_flascc.swc: $(wildcard weave_flascc/*)
#	"$(FLASCC)/usr/bin/g++" $(BASE_CFLAGS) -flto-api=weave_flascc/exports.txt -O4 weave_flascc/*.cpp weave_flascc/*.c -emit-swc=weave.flascc -o $@
#.SECONDEXPANSION:
#%.swc: $$(wildcard %/*)
#	"$(FLASCC)/usr/bin/g++" $(BASE_CFLAGS) -flto-api=$*/exports.txt -O4 $*/*.cpp -emit-swc=weave.$* -o $@

clean:
	rm -f *.swc *.o *.oo timetest

# http://www.cprogramming.com/tutorial/makefiles_continued.html
# http://stackoverflow.com/questions/6637088/makefile-pattern-rule-referencing-stem-in-dependencies
# http://www.gnu.org/software/make/manual/html_node/Secondary-Expansion.html
