/* SPDX-License-Identifier: GPL-2.0 */
/* ld script to make ARM Linux kernel
 * taken from the i386 version by Russell King
 * Written by Martin Mares <mj@atrey.karlin.mff.cuni.cz>
 */

/* No __ro_after_init data in the .rodata section - which will always be ro */
#define RO_AFTER_INIT_DATA

#include <linux/sizes.h>

#include <asm-generic/vmlinux.lds.h>
#include <asm/cache.h>
#include <asm/thread_info.h>
#include <asm/memory.h>
#include <asm/page.h>

/*
 * ld.lld does not support NOCROSSREFS:
 * https://github.com/ClangBuiltLinux/linux/issues/1609
 */
#ifdef CONFIG_LD_IS_LLD
#define NOCROSSREFS
#endif

/* Set start/end symbol names to the LMA for the section */
#define ARM_LMA(sym, section)						\
	sym##_start = LOADADDR(section);				\
	sym##_end = LOADADDR(section) + SIZEOF(section)

#define PROC_INFO							\
	. = ALIGN(4);							\
	VMLINUX_SYMBOL(__proc_info_begin) = .;				\
	*(.proc.info.init)						\
	VMLINUX_SYMBOL(__proc_info_end) = .;

#define IDMAP_TEXT							\
	ALIGN_FUNCTION();						\
	VMLINUX_SYMBOL(__idmap_text_start) = .;				\
	*(.idmap.text)							\
	VMLINUX_SYMBOL(__idmap_text_end) = .;				\
	. = ALIGN(PAGE_SIZE);						\
	VMLINUX_SYMBOL(__hyp_idmap_text_start) = .;			\
	*(.hyp.idmap.text)						\
	VMLINUX_SYMBOL(__hyp_idmap_text_end) = .;

#ifdef CONFIG_HOTPLUG_CPU
#define ARM_CPU_DISCARD(x)
#define ARM_CPU_KEEP(x)		x
#else
#define ARM_CPU_DISCARD(x)	x
#define ARM_CPU_KEEP(x)
#endif

#if (defined(CONFIG_SMP_ON_UP) && !defined(CONFIG_DEBUG_SPINLOCK)) || \
	defined(CONFIG_GENERIC_BUG)
#define ARM_EXIT_KEEP(x)	x
#define ARM_EXIT_DISCARD(x)
#else
#define ARM_EXIT_KEEP(x)
#define ARM_EXIT_DISCARD(x)	x
#endif

OUTPUT_ARCH(arm)
ENTRY(stext)

#ifndef __ARMEB__
jiffies = jiffies_64;
#else
jiffies = jiffies_64 + 4;
#endif

SECTIONS
{
	/*
	 * XXX: The linker does not define how output sections are
	 * assigned to input sections when there are multiple statements
	 * matching the same input section name.  There is no documented
	 * order of matching.
	 *
	 * unwind exit sections must be discarded before the rest of the
	 * unwind sections get included.
	 */
	/DISCARD/ : {
		*(.ARM.exidx.exit.text)
		*(.ARM.extab.exit.text)
		ARM_CPU_DISCARD(*(.ARM.exidx.cpuexit.text))
		ARM_CPU_DISCARD(*(.ARM.extab.cpuexit.text))
		ARM_EXIT_DISCARD(EXIT_TEXT)
		ARM_EXIT_DISCARD(EXIT_DATA)
		EXIT_CALL
#ifndef CONFIG_MMU
		*(.text.fixup)
		*(__ex_table)
#endif
		*(.alt.smp.init)
		*(.discard)
		*(.discard.*)
	}

	. = XIP_VIRT_ADDR(CONFIG_XIP_PHYS_ADDR);
	_xiprom = .;			/* XIP ROM area to be mapped */

	.head.text : {
		_text = .;
		HEAD_TEXT
	}

	.text : {			/* Real text segment		*/
		_stext = .;		/* Text and read-only data	*/
			IDMAP_TEXT
			__exception_text_start = .;
			*(.exception.text)
			__exception_text_end = .;
			IRQENTRY_TEXT
			TEXT_TEXT
			SCHED_TEXT
			CPUIDLE_TEXT
			LOCK_TEXT
			KPROBES_TEXT
			*(.gnu.warning)
			*(.glue_7)
			*(.glue_7t)
		. = ALIGN(4);
		*(.got)			/* Global offset table		*/
			ARM_CPU_KEEP(PROC_INFO)
	}

	RO_DATA(PAGE_SIZE)

	. = ALIGN(4);
	__ex_table : AT(ADDR(__ex_table) - LOAD_OFFSET) {
		__start___ex_table = .;
#ifdef CONFIG_MMU
		*(__ex_table)
#endif
		__stop___ex_table = .;
	}

#ifdef CONFIG_ARM_UNWIND
	/*
	 * Stack unwinding tables
	 */
	. = ALIGN(8);
	.ARM.unwind_idx : {
		__start_unwind_idx = .;
		*(.ARM.exidx*)
		__stop_unwind_idx = .;
	}
	.ARM.unwind_tab : {
		__start_unwind_tab = .;
		*(.ARM.extab*)
		__stop_unwind_tab = .;
	}
#endif

	NOTES

	_etext = .;			/* End of text and rodata section */

	/*
	 * The vectors and stubs are relocatable code, and the
	 * only thing that matters is their relative offsets
	 */
	__vectors_lma = .;
	OVERLAY 0xffff0000 : NOCROSSREFS AT(__vectors_lma) {
		.vectors {
			*(.vectors)
		}
		.vectors.bhb.loop8 {
			*(.vectors.bhb.loop8)
		}
		.vectors.bhb.bpiall {
			*(.vectors.bhb.bpiall)
		}
	}
	ARM_LMA(__vectors, .vectors);
	ARM_LMA(__vectors_bhb_loop8, .vectors.bhb.loop8);
	ARM_LMA(__vectors_bhb_bpiall, .vectors.bhb.bpiall);
	. = __vectors_lma + SIZEOF(.vectors) +
		SIZEOF(.vectors.bhb.loop8) +
		SIZEOF(.vectors.bhb.bpiall);

	__stubs_lma = .;
	.stubs ADDR(.vectors) + 0x1000 : AT(__stubs_lma) {
		*(.stubs)
	}
	ARM_LMA(__stubs, .stubs);
	. = __stubs_lma + SIZEOF(.stubs);

	PROVIDE(vector_fiq_offset = vector_fiq - ADDR(.vectors));

	INIT_TEXT_SECTION(8)
	.exit.text : {
		ARM_EXIT_KEEP(EXIT_TEXT)
	}
	.init.proc.info : {
		ARM_CPU_DISCARD(PROC_INFO)
	}
	.init.arch.info : {
		__arch_info_begin = .;
		*(.arch.info.init)
		__arch_info_end = .;
	}
	.init.tagtable : {
		__tagtable_begin = .;
		*(.taglist.init)
		__tagtable_end = .;
	}
	.init.rodata : {
		INIT_SETUP(16)
		INIT_CALLS
		CON_INITCALL
		SECURITY_INITCALL
		INIT_RAM_FS
	}

#ifdef CONFIG_ARM_MPU
	. = ALIGN(SZ_128K);
#endif
	_exiprom = .;			/* End of XIP ROM area */

/*
 * From this point, stuff is considered writable and will be copied to RAM
 */
	__data_loc = ALIGN(4);		/* location in file */
	. = PAGE_OFFSET + TEXT_OFFSET;	/* location in memory */
#undef LOAD_OFFSET
#define LOAD_OFFSET (PAGE_OFFSET + TEXT_OFFSET - __data_loc)

	. = ALIGN(THREAD_SIZE);
	_sdata = .;
	RW_DATA_SECTION(L1_CACHE_BYTES, PAGE_SIZE, THREAD_SIZE)
	.data.ro_after_init : AT(ADDR(.data.ro_after_init) - LOAD_OFFSET) {
		*(.data..ro_after_init)
	}
	_edata = .;

	. = ALIGN(PAGE_SIZE);
	__init_begin = .;
	.init.data : AT(ADDR(.init.data) - LOAD_OFFSET) {
		INIT_DATA
	}
	.exit.data : AT(ADDR(.exit.data) - LOAD_OFFSET) {
		ARM_EXIT_KEEP(EXIT_DATA)
	}
#ifdef CONFIG_SMP
	PERCPU_SECTION(L1_CACHE_BYTES)
#endif

	/*
	 * End of copied data. We need a dummy section to get its LMA.
	 * Also located before final ALIGN() as trailing padding is not stored
	 * in the resulting binary file and useless to copy.
	 */
	.data.endmark : AT(ADDR(.data.endmark) - LOAD_OFFSET) { }
	_edata_loc = LOADADDR(.data.endmark);

	. = ALIGN(PAGE_SIZE);
	__init_end = .;

#ifdef CONFIG_HAVE_TCM
        /*
	 * We align everything to a page boundary so we can
	 * free it after init has commenced and TCM contents have
	 * been copied to its destination.
	 */
	.tcm_start : {
		. = ALIGN(PAGE_SIZE);
		__tcm_start = .;
		__itcm_start = .;
	}

	/*
	 * Link these to the ITCM RAM
	 * Put VMA to the TCM address and LMA to the common RAM
	 * and we'll upload the contents from RAM to TCM and free
	 * the used RAM after that.
	 */
	.text_itcm ITCM_OFFSET : AT(__itcm_start)
	{
		__sitcm_text = .;
		*(.tcm.text)
		*(.tcm.rodata)
		. = ALIGN(4);
		__eitcm_text = .;
	}

	/*
	 * Reset the dot pointer, this is needed to create the
	 * relative __dtcm_start below (to be used as extern in code).
	 */
	. = ADDR(.tcm_start) + SIZEOF(.tcm_start) + SIZEOF(.text_itcm);

	.dtcm_start : {
		__dtcm_start = .;
	}

	/* TODO: add remainder of ITCM as well, that can be used for data! */
	.data_dtcm DTCM_OFFSET : AT(__dtcm_start)
	{
		. = ALIGN(4);
		__sdtcm_data = .;
		*(.tcm.data)
		. = ALIGN(4);
		__edtcm_data = .;
	}

	/* Reset the dot pointer or the linker gets confused */
	. = ADDR(.dtcm_start) + SIZEOF(.data_dtcm);

	/* End marker for freeing TCM copy in linked object */
	.tcm_end : AT(ADDR(.dtcm_start) + SIZEOF(.data_dtcm)){
		. = ALIGN(PAGE_SIZE);
		__tcm_end = .;
	}
#endif

	BSS_SECTION(0, 0, 8)
	_end = .;

	STABS_DEBUG
}

/*
 * These must never be empty
 * If you have to comment these two assert statements out, your
 * binutils is too old (for other reasons as well)
 */
ASSERT((__proc_info_end - __proc_info_begin), "missing CPU support")
ASSERT((__arch_info_end - __arch_info_begin), "no machine record defined")

/*
 * The HYP init code can't be more than a page long,
 * and should not cross a page boundary.
 * The above comment applies as well.
 */
ASSERT(__hyp_idmap_text_end - (__hyp_idmap_text_start & PAGE_MASK) <= PAGE_SIZE,
	"HYP init code too big or misaligned")

#ifdef CONFIG_XIP_DEFLATED_DATA
/*
 * The .bss is used as a stack area for __inflate_kernel_data() whose stack
 * frame is 9568 bytes. Make sure it has extra room left.
 */
ASSERT((_end - __bss_start) >= 12288, ".bss too small for CONFIG_XIP_DEFLATED_DATA")
#endif

#if defined(CONFIG_ARM_MPU) && !defined(CONFIG_COMPILE_TEST)
/*
 * Due to PMSAv7 restriction on base address and size we have to
 * enforce minimal alignment restrictions. It was seen that weaker
 * alignment restriction on _xiprom will likely force XIP address
 * space spawns multiple MPU regions thus it is likely we run in
 * situation when we are reprogramming MPU region we run on with
 * something which doesn't cover reprogramming code itself, so as soon
 * as we update MPU settings we'd immediately try to execute straight
 * from background region which is XN.
 * It seem that alignment in 1M should suit most users.
 * _exiprom is aligned as 1/8 of 1M so can be covered by subregion
 * disable
 */
ASSERT(!(_xiprom & (SZ_1M - 1)), "XIP start address may cause MPU programming issues")
ASSERT(!(_exiprom & (SZ_128K - 1)), "XIP end address may cause MPU programming issues")
#endif
