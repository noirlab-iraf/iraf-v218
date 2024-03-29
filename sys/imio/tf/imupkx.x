# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

# IMUPK? -- Convert an array of pixels of datatype DTYPE into the datatype
# specified by the IMUPK? suffix character.

procedure imupkx (a, b, npix, dtype)

complex	b[npix]
int	a[npix], npix, dtype

begin
	switch (dtype) {
	case TY_USHORT:
	    call achtux (a, b, npix)
	case TY_SHORT:
	    call achtsx (a, b, npix)
	case TY_INT:
	    call achtix (a, b, npix)
	case TY_LONG:
	    call achtlx (a, b, npix)
	case TY_REAL:
	    call achtrx (a, b, npix)
	case TY_DOUBLE:
	    call achtdx (a, b, npix)
	case TY_COMPLEX:
	    call achtxx (a, b, npix)
	default:
	    call error (1, "Unknown datatype in imagefile")
	}
end


