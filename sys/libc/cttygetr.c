/* Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.
*/

#define	import_spp
#define	import_libc
#define	import_xnames
#include <iraf.h>

/* C_TTYGETR -- Get the value of a termcap capability of type real.
** Zero is returned if the device does not have such a capability or if
** the the value string cannot be interpreted as a real.
*/
float
c_ttygetr (
  XINT	tty,			/* tty descriptor		*/
  char	*cap			/* two char capability name	*/
)
{
	XINT  x_tty = tty;
        XREAL TTYGETR (XPOINTER *tty, XCHAR *cap);

	return ((float) TTYGETR (&x_tty, c_sppstr(cap)));
}
