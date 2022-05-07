# Makefile for a cpp program
# How to use:
# 1. Copy this file to the directory of your project and rename it to Makefile/makefile.
# 2. Scan over the directory tree and make sure you have all the files you need where you need them.
# 3. Run make to build the program.
# Note:
# the makefile will create a dependency file in the same directory as the object file for
# each object file, so ideally for each '.c' file there will be a '.o' and a '.d' file.

RM=rm -f

# verbose or not
VERBOSE=0

# Compilers and linker
CXX=g++
CXXFLAGS= -Wall

# flags to make the .d files
DEPFLAGS= -MMD -MP

LINK=g++
LINKFLAGS= -static

# program executable and the command to run it
BINFILE=run.bin
RUN=./run.bin

# external libraries
EXTERNAL_LIBS=
# project directories
BINDIR=./bin
OBJDIR=./obj
INCDIR=./inc
SRCDIR=./src
RESDIR=./res
LIBOBJDIR=./lib/obj
LIBINCDIR=./lib/inc

# list of directories to initialize when running the 'init' target
DIRS=$(BINDIR) $(OBJDIR) $(INCDIR) $(SRCDIR) $(RESDIR) $(LIBOBJDIR) $(LIBINCDIR)

# project files
CXX_SRCFILES=$(wildcard $(SRCDIR)/*.cpp)
CXX_INCFILES=$(wildcard $(INCDIR)/*.h)
# object files and their dependencies
CXX_OBJFILES=$(patsubst $(SRCDIR)%.cpp,$(OBJDIR)%.o,$(CXX_SRCFILES))
CXX_DEPFILES=$(patsubst $(SRCDIR)%.cpp,$(OBJDIR)%.d,$(CXX_SRCFILES))

LOCAL_LIB_OBJS=$(wildcard $(LIBOBJDIR)/*.o)

BINTARGET=$(BINDIR)/$(BINFILE)

.PHONY: all init run clean clean-bin help
.SILENT: clean clean-obj init help

# build and link the executable
all: $(BINTARGET)
# create the project directories
init:
	echo "Initializing project (creating directories)"
	mkdir -p $(DIRS)
# run the program
run: all
	$(RUN)
# clean object files
clean: clean-obj
	echo "Cleaning binary files"
	$(RM) $(BINDIR)/*.bin
# clean binfiles
clean-obj:
	echo "Cleaning object files"
	$(RM) $(OBJDIR)/*.o
# help message
help:
	echo "Usage: make [target]"
	echo "Available targets:"
	echo "all		compile and link"
	echo "init		initialize project (create directories)"
	echo "run		run the program"
	echo "clean		clean object and binary files"
	echo "clean-obj	clean object files"
	echo "help		show this help message"

# compile each file based only on its dependencies
-include $(CXX_DEPFILES)

# make cpp objects
$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@echo "Compiling $@ : ($<)"
	@$(CXX) $(CXXFLAGS) $(DEPFLAGS) -c $< -o $@

# link the program
$(BINTARGET): $(CXX_OBJFILES)
	@echo "Link all into $(BINTARGET)"
# listing the files linked if verbose is on
ifeq ($(VERBOSE),1)
	@echo "Object files:"
ifneq ($(strip $(CXX_OBJFILES)),)
	@echo "	$(CXX_OBJFILES)"
else
	@echo "	*** no cpp object files ***"
endif
	@echo "Libraries:"
ifneq ($(strip $(EXTERNAL_LIBS)),)
	@echo $(EXTERNAL_LIBS)
else
	@echo "	*** no external libraries ***"
endif
ifneq ($(strip $(LOCAL_LIB_OBJS)),)
	@echo $(LOCAL_LIB_OBJS)
else
	@echo "	*** no local libraries ***"
endif
endif
	@$(LINK) $(LINKFLAGS) $(EXTERNAL_LIBS) $(CXX_OBJFILES) $(LOCAL_LIB_OBJS) -o $@
