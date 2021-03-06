changecom(`/*', `*/')dnl
/*
 * %CopyrightBegin%
 * 
 * Copyright Ericsson AB 2004-2009. All Rights Reserved.
 * 
 * The contents of this file are subject to the Erlang Public License,
 * Version 1.1, (the "License"); you may not use this file except in
 * compliance with the License. You should have received a copy of the
 * Erlang Public License along with this software. If not, it can be
 * retrieved online at http://www.erlang.org/.
 * 
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 * 
 * %CopyrightEnd%
 */
/*
 * $Id$
 */

include(`hipe/hipe_ppc_asm.m4')
#`include' "hipe_literals.h"

	.text
	.p2align 2

`#define TEST_GOT_MBUF		LOAD r4, P_MBUF(P) SEMI CMPI r4, 0 SEMI bne- 3f SEMI 2:
#define JOIN3(A,B,C)		A##B##C
#define HANDLE_GOT_MBUF(ARITY)	3: bl CSYM(JOIN3(nbif_,ARITY,_gc_after_bif)) SEMI b 2b'

/*
 * standard_bif_interface_1(nbif_name, cbif_name)
 * standard_bif_interface_2(nbif_name, cbif_name)
 * standard_bif_interface_3(nbif_name, cbif_name)
 *
 * Generate native interface for a BIF with 1-3 parameters and
 * standard failure mode.
 */
define(standard_bif_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. Check for exception. */
	CMPI	r3, THE_NON_VALUE
	RESTORE_CONTEXT_BIF
	beq-	1f
	NBIF_RET(1)
1:	/* workaround for bc:s small offset operand */
	b	CSYM(nbif_1_simple_exception)
	HANDLE_GOT_MBUF(1)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(standard_bif_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,2,0)
	NBIF_ARG(r5,2,1)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. Check for exception. */
	CMPI	r3, THE_NON_VALUE
	RESTORE_CONTEXT_BIF
	beq-	1f
	NBIF_RET(2)
1:	/* workaround for bc:s small offset operand */
	b	CSYM(nbif_2_simple_exception)
	HANDLE_GOT_MBUF(2)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(standard_bif_interface_3,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,3,0)
	NBIF_ARG(r5,3,1)
	NBIF_ARG(r6,3,2)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. Check for exception. */
	CMPI	r3, THE_NON_VALUE
	RESTORE_CONTEXT_BIF
	beq-	1f
	NBIF_RET(3)
1:	/* workaround for bc:s small offset operand */
	b	CSYM(nbif_3_simple_exception)
	HANDLE_GOT_MBUF(3)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

/*
 * trap_bif_interface_0(nbif_name, cbif_name)
 *
 * Generate native interface for a BIF with 0 parameters and
 * trap-only failure mode.
 */
define(trap_bif_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. Check for exception. */
	CMPI	r3, THE_NON_VALUE
	RESTORE_CONTEXT_BIF
	beq-	1f
	NBIF_RET(0)
1:	/* workaround for bc:s small offset operand */
	b	CSYM(nbif_0_trap_exception)
	HANDLE_GOT_MBUF(0)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

/*
 * gc_bif_interface_0(nbif_name, cbif_name)
 * gc_bif_interface_1(nbif_name, cbif_name)
 * gc_bif_interface_2(nbif_name, cbif_name)
 *
 * Generate native interface for a BIF with 0-2 parameters and
 * standard failure mode.
 * The BIF may do a GC.
 */
define(gc_bif_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. */
	RESTORE_CONTEXT_GC
	NBIF_RET(0)
	HANDLE_GOT_MBUF(0)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(gc_bif_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. Check for exception. */
	CMPI	r3, THE_NON_VALUE
	RESTORE_CONTEXT_GC
	beq-	1f
	NBIF_RET(1)
1:	/* workaround for bc:s small offset operand */
	b	CSYM(nbif_1_simple_exception)
	HANDLE_GOT_MBUF(1)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(gc_bif_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,2,0)
	NBIF_ARG(r5,2,1)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. Check for exception. */
	CMPI	r3, THE_NON_VALUE
	RESTORE_CONTEXT_GC
	beq-	1f
	NBIF_RET(2)
1:	/* workaround for bc:s small offset operand */
	b	CSYM(nbif_2_simple_exception)
	HANDLE_GOT_MBUF(2)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

/*
 * gc_nofail_primop_interface_1(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with implicit P
 * parameter, 1 ordinary parameter and no failure mode.
 * The primop may do a GC.
 */
define(gc_nofail_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
	bl	CSYM($2)

	/* Restore registers. */
	RESTORE_CONTEXT_GC
	NBIF_RET(1)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

/*
 * nofail_primop_interface_0(nbif_name, cbif_name)
 * nofail_primop_interface_1(nbif_name, cbif_name)
 * nofail_primop_interface_2(nbif_name, cbif_name)
 * nofail_primop_interface_3(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with implicit P
 * parameter, 0-3 ordinary parameters and no failure mode.
 * Also used for guard BIFs.
 */
define(nofail_primop_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(0)
	HANDLE_GOT_MBUF(0)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(nofail_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(1)
	HANDLE_GOT_MBUF(1)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(nofail_primop_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,2,0)
	NBIF_ARG(r5,2,1)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(2)
	HANDLE_GOT_MBUF(2)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(nofail_primop_interface_3,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,3,0)
	NBIF_ARG(r5,3,1)
	NBIF_ARG(r6,3,2)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	CSYM($2)
	TEST_GOT_MBUF

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(3)
	HANDLE_GOT_MBUF(3)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

/*
 * nocons_nofail_primop_interface_0(nbif_name, cbif_name)
 * nocons_nofail_primop_interface_1(nbif_name, cbif_name)
 * nocons_nofail_primop_interface_2(nbif_name, cbif_name)
 * nocons_nofail_primop_interface_3(nbif_name, cbif_name)
 * nocons_nofail_primop_interface_5(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with implicit P
 * parameter, 0-3 or 5 ordinary parameters, and no failure mode.
 * The primop cannot CONS or gc.
 */
define(nocons_nofail_primop_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),0)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(nocons_nofail_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,1,0)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),1)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(nocons_nofail_primop_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,2,0)
	NBIF_ARG(r5,2,1)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),2)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(nocons_nofail_primop_interface_3,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,3,0)
	NBIF_ARG(r5,3,1)
	NBIF_ARG(r6,3,2)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),3)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(nocons_nofail_primop_interface_5,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	mr	r3, P
	NBIF_ARG(r4,5,0)
	NBIF_ARG(r5,5,1)
	NBIF_ARG(r6,5,2)
	NBIF_ARG(r7,5,3)
	NBIF_ARG(r8,5,4)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),5)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

/*
 * noproc_primop_interface_0(nbif_name, cbif_name)
 * noproc_primop_interface_1(nbif_name, cbif_name)
 * noproc_primop_interface_2(nbif_name, cbif_name)
 * noproc_primop_interface_3(nbif_name, cbif_name)
 * noproc_primop_interface_5(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with no implicit P
 * parameter, 0-3 or 5 ordinary parameters, and no failure mode.
 * The primop cannot CONS or gc.
 */
define(noproc_primop_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* XXX: this case is always trivial; how to suppress the branch? */
	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),0)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(noproc_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	NBIF_ARG(r3,1,0)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),1)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(noproc_primop_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	NBIF_ARG(r3,2,0)
	NBIF_ARG(r4,2,1)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),2)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(noproc_primop_interface_3,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	NBIF_ARG(r3,3,0)
	NBIF_ARG(r4,3,1)
	NBIF_ARG(r5,3,2)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),3)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

define(noproc_primop_interface_5,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	GLOBAL(ASYM($1))
ASYM($1):
	/* Set up C argument registers. */
	NBIF_ARG(r3,5,0)
	NBIF_ARG(r4,5,1)
	NBIF_ARG(r5,5,2)
	NBIF_ARG(r6,5,3)
	NBIF_ARG(r7,5,4)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(CSYM($2),5)
	SET_SIZE(ASYM($1))
	TYPE_FUNCTION(ASYM($1))
#endif')

include(`hipe/hipe_bif_list.m4')

`#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif'
