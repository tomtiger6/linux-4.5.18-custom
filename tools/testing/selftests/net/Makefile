# SPDX-License-Identifier: GPL-2.0
# Makefile for net selftests

CFLAGS =  -Wall -Wl,--no-as-needed -O2 -g
CFLAGS += -I../../../../usr/include/

TEST_PROGS := run_netsocktests run_afpackettests test_bpf.sh netdevice.sh rtnetlink.sh
TEST_PROGS += fib-onlink-tests.sh
TEST_PROGS += msg_zerocopy.sh
TEST_PROGS_EXTENDED := in_netns.sh
TEST_GEN_FILES =  socket
TEST_GEN_FILES += psock_fanout psock_tpacket msg_zerocopy
TEST_GEN_PROGS = reuseport_bpf reuseport_bpf_cpu reuseport_bpf_numa
TEST_GEN_PROGS += reuseport_dualstack reuseaddr_conflict

TEST_FILES := settings

KSFT_KHDR_INSTALL := 1
include ../lib.mk

$(OUTPUT)/reuseport_bpf_numa: LDLIBS += -lnuma
