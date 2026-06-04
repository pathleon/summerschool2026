# SPDX-FileCopyrightText: 2010 CSC - IT Center for Science Ltd. <www.csc.fi>
#
# SPDX-License-Identifier: MIT

.DEFAULT_GOAL := all

ifeq ($(COMP),)
COMP=lumi
endif

# Include the "heat-shared" Makefile: fills in HEAT_SHARED_CFLAGS and adds rule for building HEAT_COMMON_LIB (static)
HEAT_SHARED_DIR := ../../../../../heat-shared
include $(HEAT_SHARED_DIR)/Makefile-common

ifeq ($(COMP),gnu)
CXX=mpicxx
CC=mpicc
CCFLAGS=-g -O3 -march=native -Wall -DNDEBUG
LDFLAGS=
LIBS=
endif

ifeq ($(COMP),intel)
CXX=mpicxx
CC=icc
CCFLAGS=-g -O3 -xHost -DNDEBUG
LDFLAGS=
LIBS=
endif

ifeq ($(COMP),lumi)
CXX=CC
CC=cc
CCFLAGS=-O3 -Wall
LDFLAGS=
LIBS=
endif


EXE=heat_mpi
OBJS=main.o heat.o core.o setup.o io.o utilities.o

all: $(EXE)

utilities.o: utilities.cpp heat.hpp
heat.o: heat.cpp heat.hpp matrix.hpp
core.o: core.cpp heat.hpp
setup.o: setup.cpp heat.hpp
io.o: io.cpp heat.hpp matrix.hpp
main.o: main.cpp heat.hpp

$(EXE): $(OBJS) $(HEAT_COMMON_LIB)
	$(CXX) $(CCFLAGS) $(HEAT_SHARED_CFLAGS) $(OBJS) $(HEAT_COMMON_LIB) -o $@ $(LDFLAGS) $(LIBS)

%.o: %.cpp
	$(CXX) $(CCFLAGS) $(HEAT_SHARED_CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CCFLAGS) $(HEAT_SHARED_CFLAGS) -c $< -o $@

.PHONY: clean
clean: heat-common-clean
	-/bin/rm -f $(EXE) $(OBJS) a.out *.o *.png *~
