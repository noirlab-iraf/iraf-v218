# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	"../icombine.h"


# IC_GROW --  Reject neigbors of rejected pixels.
# The rejected pixels are marked by having nonzero ids beyond the number
# of included pixels.  The pixels rejected here are given zero ids
# to avoid growing of the pixels rejected here.  The unweighted average
# can be updated but any rejected pixels requires the median to be
# recomputed.  When the number of pixels at a grow point reaches nkeep 
# no further pixels are rejected.  Note that the rejection order is not
# based on the magnitude of the residuals and so a grow from a weakly
# rejected image pixel may take precedence over a grow from a strongly
# rejected image pixel.

procedure ic_grows (d, m, n, nimages, npts, average)

pointer	d[ARB]			# Data pointers
pointer	m[ARB]			# Image id pointers
int	n[npts]			# Number of good pixels
int	nimages			# Number of images
int	npts			# Number of output points per line
real	average[npts]		# Average

int	i1, i2, j1, j2, k1, k2, l, is, ie, n2, maxkeep
pointer	mp1, mp2

include	"../icombine.com"

begin
	if (dflag == D_NONE)
	    return

	do i1 = 1, npts {
	    k1 = i1 - 1
	    is = max (1, i1 - grow)
	    ie = min (npts, i1 + grow)
	    do j1 = n[i1]+1, nimages {
		l = Memi[m[j1]+k1]
		if (l == 0)
		    next
		if (combine == MEDIAN)
		    docombine = true

		do i2 = is, ie {
		    if (i2 == i1)
			next
		    k2 = i2 - 1
		    n2 = n[i2]
		    if (nkeep < 0)
			maxkeep = max (0, n2 + nkeep)
		    else
			maxkeep = min (n2, nkeep)
		    if (n2 <= maxkeep)
			next
		    do j2 = 1, n2 {
			mp1 = m[j2] + k2
			if (Memi[mp1] == l) {
			    if (!docombine && n2 > 1)
				average[i2] =
				    (n2*average[i2] - Mems[d[j2]+k2]) / (n2-1)
			    mp2 = m[n2] + k2
			    if (j2 < n2) {
				Mems[d[j2]+k2] = Mems[d[n2]+k2]
				Memi[mp1] = Memi[mp2]
			    }
			    Memi[mp2] = 0
			    n[i2] = n2 - 1
			    break
			}
		    }
		}
	    }
	}
end

# IC_GROW --  Reject neigbors of rejected pixels.
# The rejected pixels are marked by having nonzero ids beyond the number
# of included pixels.  The pixels rejected here are given zero ids
# to avoid growing of the pixels rejected here.  The unweighted average
# can be updated but any rejected pixels requires the median to be
# recomputed.  When the number of pixels at a grow point reaches nkeep 
# no further pixels are rejected.  Note that the rejection order is not
# based on the magnitude of the residuals and so a grow from a weakly
# rejected image pixel may take precedence over a grow from a strongly
# rejected image pixel.

procedure ic_growr (d, m, n, nimages, npts, average)

pointer	d[ARB]			# Data pointers
pointer	m[ARB]			# Image id pointers
int	n[npts]			# Number of good pixels
int	nimages			# Number of images
int	npts			# Number of output points per line
real	average[npts]		# Average

int	i1, i2, j1, j2, k1, k2, l, is, ie, n2, maxkeep
pointer	mp1, mp2

include	"../icombine.com"

begin
	if (dflag == D_NONE)
	    return

	do i1 = 1, npts {
	    k1 = i1 - 1
	    is = max (1, i1 - grow)
	    ie = min (npts, i1 + grow)
	    do j1 = n[i1]+1, nimages {
		l = Memi[m[j1]+k1]
		if (l == 0)
		    next
		if (combine == MEDIAN)
		    docombine = true

		do i2 = is, ie {
		    if (i2 == i1)
			next
		    k2 = i2 - 1
		    n2 = n[i2]
		    if (nkeep < 0)
			maxkeep = max (0, n2 + nkeep)
		    else
			maxkeep = min (n2, nkeep)
		    if (n2 <= maxkeep)
			next
		    do j2 = 1, n2 {
			mp1 = m[j2] + k2
			if (Memi[mp1] == l) {
			    if (!docombine && n2 > 1)
				average[i2] =
				    (n2*average[i2] - Memr[d[j2]+k2]) / (n2-1)
			    mp2 = m[n2] + k2
			    if (j2 < n2) {
				Memr[d[j2]+k2] = Memr[d[n2]+k2]
				Memi[mp1] = Memi[mp2]
			    }
			    Memi[mp2] = 0
			    n[i2] = n2 - 1
			    break
			}
		    }
		}
	    }
	}
end

