# SPDX-License-Identifier: GPL-2.0
TARGETS = android
TARGETS += bpf
TARGETS += breakpoints
TARGETS += capabilities
TARGETS += cpufreq
TARGETS += cpu-hotplug
TARGETS += efivarfs
TARGETS += exec
TARGETS += filesystems
TARGETS += firmware
TARGETS += ftrace
TARGETS += futex
TARGETS += gpio
TARGETS += intel_pstate
TARGETS += ipc
TARGETS += kcmp
TARGETS += lib
TARGETS += membarrier
TARGETS += memfd
TARGETS += memory-hotplug
TARGETS += mount
TARGETS += mqueue
TARGETS += net
TARGETS += netfilter
TARGETS += nsfs
TARGETS += powerpc
TARGETS += pstore
TARGETS += ptrace
TARGETS += seccomp
TARGETS += sigaltstack
TARGETS += size
TARGETS += splice
TARGETS += static_keys
TARGETS += sync
TARGETS += sysctl
ifneq (1, $(quicktest))
TARGETS += timers
endif
TARGETS += user
TARGETS += vm
TARGETS += x86
TARGETS += zram
#Please keep the TARGETS list alphabetically sorted
# Run "make quicktest=1 run_tests" or
# "make quicktest=1 kselftest" from top level Makefile

TARGETS_HOTPLUG = cpu-hotplug
TARGETS_HOTPLUG += memory-hotplug

# Clear LDFLAGS and MAKEFLAGS if called from main
# Makefile to avoid test build failures when test
# Makefile doesn't have explicit build rules.
ifeq (1,$(MAKELEVEL))
override LDFLAGS =
override MAKEFLAGS =
endif

ifneq ($(KBUILD_SRC),)
override LDFLAGS =
endif

ifneq ($(O),)
	BUILD := $(O)
else
	ifneq ($(KBUILD_OUTPUT),)
		BUILD := $(KBUILD_OUTPUT)
	else
		BUILD := $(shell pwd)
		DEFAULT_INSTALL_HDR_PATH := 1
	endif
endif

# KSFT_TAP_LEVEL is used from KSFT framework to prevent nested TAP header
# printing from tests. Applicable to run_tests case where run_tests adds
# TAP header prior running tests and when a test program invokes another
# with system() call. Export it here to cover override RUN_TESTS defines.
export KSFT_TAP_LEVEL=`echo 1`

# Prepare for headers install
top_srcdir ?= ../../..
include $(top_srcdir)/scripts/subarch.include
ARCH           ?= $(SUBARCH)
export KSFT_KHDR_INSTALL_DONE := 1
export BUILD

# set default goal to all, so make without a target runs all, even when
# all isn't the first target in the file.
.DEFAULT_GOAL := all

# Install headers here once for all tests. KSFT_KHDR_INSTALL_DONE
# is used to avoid running headers_install from lib.mk.
# Invoke headers install with --no-builtin-rules to avoid circular
# dependency in "make kselftest" case. In this case, second level
# make inherits builtin-rules which will use the rule generate
# Makefile.o and runs into
# "Circular Makefile.o <- prepare dependency dropped."
# and headers_install fails and test compile fails.
#
# O= KBUILD_OUTPUT cases don't run into this error, since main Makefile
# invokes them as sub-makes and --no-builtin-rules is not necessary,
# but doesn't cause any failures. Keep it simple and use the same
# flags in both cases.
# Local build cases: "make kselftest", "make -C" - headers are installed
# in the default INSTALL_HDR_PATH usr/include.
khdr:
ifeq (1,$(DEFAULT_INSTALL_HDR_PATH))
	make --no-builtin-rules ARCH=$(ARCH) -C $(top_srcdir) headers_install
else
	make --no-builtin-rules INSTALL_HDR_PATH=$$BUILD/usr \
		ARCH=$(ARCH) -C $(top_srcdir) headers_install
endif

all: khdr
	@for TARGET in $(TARGETS); do		\
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		mkdir $$BUILD_TARGET  -p;	\
		make OUTPUT=$$BUILD_TARGET -C $$TARGET;\
	done;

run_tests: all
	@for TARGET in $(TARGETS); do \
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		make OUTPUT=$$BUILD_TARGET -C $$TARGET run_tests;\
	done;

hotplug:
	@for TARGET in $(TARGETS_HOTPLUG); do \
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		make OUTPUT=$$BUILD_TARGET -C $$TARGET;\
	done;

run_hotplug: hotplug
	@for TARGET in $(TARGETS_HOTPLUG); do \
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		make OUTPUT=$$BUILD_TARGET -C $$TARGET run_full_test;\
	done;

clean_hotplug:
	@for TARGET in $(TARGETS_HOTPLUG); do \
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		make OUTPUT=$$BUILD_TARGET -C $$TARGET clean;\
	done;

run_pstore_crash:
	make -C pstore run_crash

INSTALL_PATH ?= install
INSTALL_PATH := $(abspath $(INSTALL_PATH))
ALL_SCRIPT := $(INSTALL_PATH)/run_kselftest.sh

install:
ifdef INSTALL_PATH
	@# Ask all targets to install their files
	mkdir -p $(INSTALL_PATH)
	@for TARGET in $(TARGETS); do \
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		make OUTPUT=$$BUILD_TARGET -C $$TARGET INSTALL_PATH=$(INSTALL_PATH)/$$TARGET install; \
	done;

	@# Ask all targets to emit their test scripts
	echo "#!/bin/sh" > $(ALL_SCRIPT)
	echo "BASE_DIR=\$$(realpath \$$(dirname \$$0))" >> $(ALL_SCRIPT)
	echo "cd \$$BASE_DIR" >> $(ALL_SCRIPT)
	echo "ROOT=\$$PWD" >> $(ALL_SCRIPT)
	echo "if [ \"\$$1\" = \"--summary\" ]; then" >> $(ALL_SCRIPT)
	echo "  OUTPUT=\$$BASE_DIR/output.log" >> $(ALL_SCRIPT)
	echo "  cat /dev/null > \$$OUTPUT" >> $(ALL_SCRIPT)
	echo "else" >> $(ALL_SCRIPT)
	echo "  OUTPUT=/dev/stdout" >> $(ALL_SCRIPT)
	echo "fi" >> $(ALL_SCRIPT)
	echo "export KSFT_TAP_LEVEL=`echo 1`" >> $(ALL_SCRIPT)

	for TARGET in $(TARGETS); do \
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		echo "echo ; echo TAP version 13" >> $(ALL_SCRIPT);	\
		echo "echo Running tests in $$TARGET" >> $(ALL_SCRIPT); \
		echo "echo ========================================" >> $(ALL_SCRIPT); \
		echo "[ -w /dev/kmsg ] && echo \"kselftest: Running tests in $$TARGET\" >> /dev/kmsg" >> $(ALL_SCRIPT); \
		echo "cd $$TARGET" >> $(ALL_SCRIPT); \
		make -s --no-print-directory OUTPUT=$$BUILD_TARGET -C $$TARGET emit_tests >> $(ALL_SCRIPT); \
		echo "cd \$$ROOT" >> $(ALL_SCRIPT); \
	done;

	chmod u+x $(ALL_SCRIPT)
else
	$(error Error: set INSTALL_PATH to use install)
endif

clean:
	@for TARGET in $(TARGETS); do \
		BUILD_TARGET=$$BUILD/$$TARGET;	\
		make OUTPUT=$$BUILD_TARGET -C $$TARGET clean;\
	done;

.PHONY: khdr all run_tests hotplug run_hotplug clean_hotplug run_pstore_crash install clean
