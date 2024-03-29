#  Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.
# 
#  ZSVJMP, ZDOJMP -- Set up a jump (non-local goto) by saving the processor
#  registers in the buffer jmpbuf.  A subsequent call to ZDOJMP restores
#  the registers, effecting a call in the context of the procedure which
#  originally called ZSVJMP, but with the new status code.  These are Fortran
#  callable procedures.
# 
# 		zsvjmp (jmp_buf, status)	# (returns status)
# 		zdojmp (jmp_buf, status)	# (passes status to zsvjmp)
# 
#  These routines are directly comparable to the UNIX setjmp/longjmp, except
#  that they are Fortran callable kernel routines, i.e., trailing underscore,
#  call by reference, and no function returns.  ZSVJMP requires an assembler
#  jacket routine to avoid modifying the call stack, but relies upon setjmp
#  to do the real work.  ZDOJMP is implemented as a portable C routine in OS,
#  calling longjmp to do the restore.  In these routines, JMP_BUF consists
#  of one longword containing the address of the STATUS variable, followed
#  by the "jmp_buf" used by setjmp/longjmp.

	.file	"zsvjmp.s"

        .globl	_zsvjmp_

_zsvjmp_:
        # In the x86_64, the first 6 arguments of a call are passed thru
        # registers.  Here, %rdi is the first arg containing the address of
        # the jmpbuf, and %rsi holds the status value.
        movq    %rsi, (%rdi)            # Store address of status in jmpbuf[0]
        movq    $0, (%rsi)              # Zero the value of status.  Note
                                        # this also clears the least
                                        # significant 4 bytes of the
                                        # register.
        addq    $8, %rdi                # Move &jmpbuf[0] to &jmpbuf[1]

        jmp     _sigsetjmp              # use sigsetjmp to do the rest

