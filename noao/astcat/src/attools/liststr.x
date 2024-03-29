include <ctype.h>



# LI_FIND_FIELDS -- This procedure finds the starting column for each field
# in the input line.  These column numbers are returned in the array
# field_pos; the number of fields is also returned.

procedure li_find_fields (linebuf, field_pos, max_fields, nfields)

char	linebuf[ARB]			#I the input buffer
int	field_pos[max_fields]		#O the output field positions
int	max_fields			#I the maximum number of fields
int	nfields				#O the computed number of fields

bool	in_field
int	ip, field_num

begin
	field_num = 1
	field_pos[1] = 1
	in_field = false

	for (ip=1; linebuf[ip] != '\n' && linebuf[ip] != EOS; ip=ip+1) {
	    if (! IS_WHITE(linebuf[ip]))
		in_field = true
	    else if (in_field) {
		in_field = false
		field_num = field_num + 1
		field_pos[field_num] = ip
	    }
	}

	field_pos[field_num+1] = ip 
	nfields = field_num
end


# LI_CAPPEND_LINE -- Fields are copied from the input buffer to the
# output buffer.

procedure li_cappend_line (inbuf, outbuf, maxch, xoffset, yoffset,
	xwidth, ywidth) 

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
int	xoffset			#I the offset to the x field
int	yoffset			#I the offset to the y field
int	xwidth			#I the width of the x field
int	ywidth			#I the width of the y field

int	ip, op
int	gstrcpy()

begin
	# Copy the input buffer into the output buffer minus the newline.
	op = 1
	for (ip = 1; ip <= maxch; ip = ip + 1) {
	    if (inbuf[ip] == '\n' || inbuf[ip] == EOS)
		break
	    outbuf[op] = inbuf[ip]
	    op = op + 1
	}

	# Add a blank.
	if (op <= maxch) {
	    outbuf[op] = ' '
	    op = op + 1
	}

	# Copy the two fields.
	op = op + gstrcpy (inbuf[xoffset], outbuf[op], min (maxch - op + 1,
	    xwidth))
	op = op + gstrcpy (inbuf[yoffset], outbuf[op], min (maxch - op + 1,
	    ywidth))

	# Add a newline.
	if (op <= maxch) {
	    outbuf[op] = '\n'
	    op = op + 1
	}
	outbuf[op] = EOS
end


define  LOGPTR          20                      # log2(maxpts) (1e6)

# LI_PQSORTI -- Vector quicksort an integer array. In this version the index
# array is actually sorted not the data array. The input and output index
# arrays may be the same.

procedure li_pqsorti (data, a, b, npix)

int     data[ARB]               # data array
int     a[ARB]                  # input index array
int     b[ARB]                  # output index array
int     npix                    # number of pixels

int     i, j, lv[LOGPTR], p, uv[LOGPTR], temp, pivot

begin
        # Initialize the indices for an inplace sort.
        call amovi (a, b, npix)

        p = 1
        lv[1] = 1
        uv[1] = npix
        while (p > 0) {


            # If only one elem in subset pop stack otherwise pivot line.
            if (lv[p] >= uv[p])
                p = p - 1
            else {
                i = lv[p] - 1
                j = uv[p]
                pivot = data[b[j]]

                while (i < j) {
                    for (i=i+1;  data[b[i]] < pivot;  i=i+1)
                        ;
                    for (j=j-1;  j > i;  j=j-1)
                        if (data[b[j]] <= pivot)
                            break
                    if (i < j) {                # out of order pair
                        temp = b[j]             # interchange elements
                        b[j] = b[i]
                        b[i] = temp
                    }
                }

                j = uv[p]                       # move pivot to position i
                temp = b[j]                     # interchange elements
                b[j] = b[i]
                b[i] = temp

                if (i-lv[p] < uv[p] - i) {      # stack so shorter done first
                    lv[p+1] = lv[p]
                    uv[p+1] = i - 1
                    lv[p] = i + 1
                } else {
                    lv[p+1] = i + 1
                    uv[p+1] = uv[p]
                    uv[p] = i - 1
                }

                p = p + 1                       # push onto stack
            }
        }
end






# LT_GET_NUM -- The field entry is converted from character to real or double
# in preparation for the transformation.  The number of significant
# digits is counted and returned as an argument; the number of chars in
# the number is returned as the function value.

int procedure li_get_numr (linebuf, fval, nsdig) 

char	linebuf[ARB]		#I the input line buffer
real	fval			#O the output floating point value
int	nsdig			#O the number of significant digits

char	ch
int 	nchar, ip
int	ctor(), stridx()

begin
	ip = 1
	nsdig = 0
	nchar = ctor (linebuf, ip, fval)
	if (nchar == 0 || fval == INDEFR)
	    return (nchar)

	# Skip leading white space.
	ip = 1
    	repeat {
	    ch = linebuf[ip]
	    if (! IS_WHITE(ch)) 
		break
	    ip = ip + 1
	} 

	# Count signifigant digits
	for (; ! IS_WHITE(ch) && ch != '\n' && ch != EOS; ch=linebuf[ip]) {
	    if (stridx (ch, "eEdD") > 0)
		break
	    if (IS_DIGIT (ch))
		nsdig = nsdig + 1
	    ip = ip + 1
	}

	return (nchar)
end


# LI_PACK_LINE -- Fields are packed into the outbuf buffer.  Transformed
# fields are converted to strings; other fields are copied from
# the input line to output buffer.

procedure li_pack_liner (inbuf, outbuf, maxch, field_pos, nfields, 
	xfield, yfield, xt, yt, xformat, yformat, nsdig_x, nsdig_y,
	min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
int	field_pos[ARB]		#I starting positions for the fields
int	nfields			#I the number of fields
int	xfield			#I the field number of the x coordinate column
int	yfield			#I the field number of the y coordinate column
real	xt			#I the transformed x coordinate
real	yt			#I the transformed y coordinate
char	xformat[ARB]		#I the output format for the x column
char	yformat[ARB]		#I the output format for the y column
int	nsdig_x			#I the number of significant digits in x
int	nsdig_y			#I the number of significant digits in y
int	min_sigdigits		#I the minimum number of significant digits

int	num_field, width, op
pointer	sp, field
int	gstrcpy()

begin
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)

	# Initialize output pointer.
	op = 1

	do num_field = 1, nfields {
	    width = field_pos[num_field + 1] - field_pos[num_field]

	    if (num_field == xfield) {
	        call li_format_fieldr (xt, Memc[field], maxch, xformat,
		    nsdig_x, width, min_sigdigits)
	    } else if (num_field == yfield) {
		call li_format_fieldr (yt, Memc[field], maxch, yformat,
		    nsdig_y, width, min_sigdigits)
	    } else {
	        # Put "width" characters from inbuf into field
		call strcpy (inbuf[field_pos[num_field]], Memc[field], width)
	    }

	    # Fields must be delimited by at least one blank.
	    if (num_field > 1 && !IS_WHITE (Memc[field])) {
		outbuf[op] = ' '
		op = op + 1
	    }

	    # Copy "field" to output buffer.
	    op = op + gstrcpy (Memc[field], outbuf[op], maxch)
	}

	outbuf[op] = '\n'
	outbuf[op+1] = EOS

	call sfree (sp)
end


# LI_NPACK_LINE -- Fields are packed into the outbuf buffer.  Transformed
# fields are converted to strings; other fields are copied from
# the input line to output buffer.

procedure li_npack_liner (inbuf, outbuf, maxch, field_pos, nfields, 
	vfields, values, nsdigits, nvalues, vformats, sz_fmt, min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
int	field_pos[ARB]		#I starting positions for the fields
int	nfields			#I the number of fields
int	vfields[ARB]		#I the fields to be formatted
real	values[ARB]		#I the field values to be formatted
int	nsdigits[ARB]		#I the number of field significant digits
int	nvalues			#I the number of fields to be formatted
char	vformats[sz_fmt,ARB]	#I the field formats
int	sz_fmt			#I the size of the format string
int	min_sigdigits		#I the minimum number of significant digits

bool	found
int	op, num_field, num_var, width
pointer	sp, field
int	gstrcpy()

begin
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)

	# Initialize output pointer.
	op = 1

	do num_field = 1, nfields {
	    width = field_pos[num_field + 1] - field_pos[num_field]

	    found = false
	    do num_var = 1, nvalues {
	        if (num_field == vfields[num_var]) {
		    found = true
		    break
		}
	    }

	    if (found) {
	        call li_format_fieldr (values[num_var], Memc[field],
		    maxch, vformats[1,num_var], nsdigits[num_var], width,
		    min_sigdigits)
	    } else {
	        # Put "width" characters from inbuf into field
		call strcpy (inbuf[field_pos[num_field]], Memc[field], width)
	    }

	    # Fields must be delimited by at least one blank.
	    if (num_field > 1 && !IS_WHITE (Memc[field])) {
		outbuf[op] = ' '
		op = op + 1
	    }

	    # Copy "field" to output buffer.
	    op = op + gstrcpy (Memc[field], outbuf[op], maxch)
	}

	outbuf[op] = '\n'
	outbuf[op+1] = EOS

	call sfree (sp)
end


# LI_APPEND_LINE -- Fields are appened to the input buffer.  Transformed
# fields are converted to strings and added to the end of the input buffer.

procedure li_append_liner (inbuf, outbuf, maxch, xt, yt, xformat, yformat,
	nsdig_x, nsdig_y, min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
real	xt			#I the transformed x coordinate
real	yt			#I the transformed y coordinate
char	xformat[ARB]		#I the output format for the x column
char	yformat[ARB]		#I the output format for the y column
int	nsdig_x			#I the number of significant digits in x
int	nsdig_y			#I the number of significant digits in y
int	min_sigdigits		#I the minimum number of significant digits

int	ip, op
pointer	sp, field
int	gstrcpy()

begin
	# Allocate some working space.
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)

	# Copy the input buffer into the output buffer minus the newline.
	op = 1
	for (ip = 1; ip <= maxch; ip = ip + 1) {
	    if (inbuf[ip] == '\n' || inbuf[ip] == EOS)
		break
	    outbuf[op] = inbuf[ip]
	    op = op + 1
	}

	# Add two blanks.
	op = op + gstrcpy ("  ", outbuf[op], maxch - op + 1)

	# Format and add the the two extra fields with a blank between.
	call li_format_fieldr (xt, Memc[field], SZ_LINE, xformat,
	    nsdig_x, 0, min_sigdigits)
	op = op + gstrcpy (Memc[field], outbuf[op], maxch - op + 1)
	if (op <= maxch) {
	    outbuf[op] = ' '
	    op = op + 1
	}
	call li_format_fieldr (yt, Memc[field], SZ_LINE, yformat,
	    nsdig_y, 0, min_sigdigits)
	op = op + gstrcpy (Memc[field], outbuf[op], maxch - op + 1)

	# Add a newline.
	if (op <= maxch) {
	    outbuf[op] = '\n'
	    op = op + 1
	}
	outbuf[op] = EOS

	call sfree (sp)
end


# LI_NAPPEND_LINE -- Fields are appened to the input buffer.  Transformed
# fields are converted to strings and added to the end of the input buffer.

procedure li_nappend_liner (inbuf, outbuf, maxch, field_pos, nfields, 
	vfields, values, nsdigits, nvalues, vformats, sz_fmt, min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
int	field_pos[ARB]		#I starting positions for the fields
int	nfields			#I the number of fields
int	vfields[ARB]		#I the fields to be formatted
real	values[ARB]		#I the field values to be formatted
int	nsdigits[ARB]		#I the number of field significant digits
int	nvalues			#I the number of fields to be formatted
char	vformats[sz_fmt,ARB]	#I the field formats
int	sz_fmt			#I the size of the format string
int	min_sigdigits		#I the minimum number of significant digits

int	num_var, ip, op, index
pointer	sp, field, nvfields
int	gstrcpy()

begin
	# Allocate some working space.
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)
	call salloc (nvfields, nvalues, TY_INT)
	do num_var = 1, nvalues
	    Memi[nvfields+num_var-1] = num_var
	call li_pqsorti (vfields, Memi[nvfields], Memi[nvfields], nvalues)

	# Copy the input buffer into the output buffer minus the newline.
	op = 1
	for (ip = 1; ip <= maxch; ip = ip + 1) {
	    if (inbuf[ip] == '\n' || inbuf[ip] == EOS)
		break
	    outbuf[op] = inbuf[ip]
	    op = op + 1
	}

	# Add two blanks.
	op = op + gstrcpy ("  ", outbuf[op], maxch - op + 1)

	do num_var = 1, nvalues {
	    index = Memi[nvfields+num_var-1]
	    call li_format_fieldr (values[index], Memc[field], SZ_LINE,
	        vformats[sz_fmt,index], nsdigits[index], 0, min_sigdigits)
	    op = op + gstrcpy (Memc[field], outbuf[op], maxch - op + 1)
	    if (num_var == nvalues) {
		if (op <= maxch) {
	    	    outbuf[op] = '\n'
	    	    op = op + 1
		}
	    } else {
		if (op <= maxch) {
	    	    outbuf[op] = ' '
	    	    op = op + 1
		}
	    }
	}

	outbuf[op] = EOS

	call sfree (sp)
end


# LI_FORMAT_FIELD -- A transformed coordinate is written into a string
# buffer.  The output field is of (at least) the same width and significance
# as the input list entry.

procedure li_format_fieldr (fval, wordbuf, maxch, format, nsdig, width,
	min_sigdigits)

real	fval			#I the input value to be formatted
char	wordbuf[maxch]		#O the output formatted string
int	maxch			#I the maximum length of the output string
char	format[ARB]		#I the output format
int	nsdig 			#I the number of sig-digits in current value
int	width			#I the width of the curent field
int	min_sigdigits		#I the minimum number of significant digits

int	fdigits, fwidth
begin
	if (format[1] == EOS) {
	    fdigits = max (min_sigdigits, nsdig)
	    fwidth = max (width, fdigits + 1)
	    call sprintf (wordbuf, maxch, "%*.*g")
	        call pargi (fwidth)
	        call pargi (fdigits)
	        call pargr (fval)
	} else {
	    call sprintf (wordbuf, maxch, format)
		call pargr (fval)
	}
end




# LT_GET_NUM -- The field entry is converted from character to real or double
# in preparation for the transformation.  The number of significant
# digits is counted and returned as an argument; the number of chars in
# the number is returned as the function value.

int procedure li_get_numd (linebuf, fval, nsdig) 

char	linebuf[ARB]		#I the input line buffer
double	fval			#O the output floating point value
int	nsdig			#O the number of significant digits

char	ch
int 	nchar, ip
int	ctod(), stridx()

begin
	ip = 1
	nsdig = 0
	nchar = ctod (linebuf, ip, fval)
	if (nchar == 0 || fval == INDEFD)
	    return (nchar)

	# Skip leading white space.
	ip = 1
    	repeat {
	    ch = linebuf[ip]
	    if (! IS_WHITE(ch)) 
		break
	    ip = ip + 1
	} 

	# Count signifigant digits
	for (; ! IS_WHITE(ch) && ch != '\n' && ch != EOS; ch=linebuf[ip]) {
	    if (stridx (ch, "eEdD") > 0)
		break
	    if (IS_DIGIT (ch))
		nsdig = nsdig + 1
	    ip = ip + 1
	}

	return (nchar)
end


# LI_PACK_LINE -- Fields are packed into the outbuf buffer.  Transformed
# fields are converted to strings; other fields are copied from
# the input line to output buffer.

procedure li_pack_lined (inbuf, outbuf, maxch, field_pos, nfields, 
	xfield, yfield, xt, yt, xformat, yformat, nsdig_x, nsdig_y,
	min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
int	field_pos[ARB]		#I starting positions for the fields
int	nfields			#I the number of fields
int	xfield			#I the field number of the x coordinate column
int	yfield			#I the field number of the y coordinate column
double	xt			#I the transformed x coordinate
double	yt			#I the transformed y coordinate
char	xformat[ARB]		#I the output format for the x column
char	yformat[ARB]		#I the output format for the y column
int	nsdig_x			#I the number of significant digits in x
int	nsdig_y			#I the number of significant digits in y
int	min_sigdigits		#I the minimum number of significant digits

int	num_field, width, op
pointer	sp, field
int	gstrcpy()

begin
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)

	# Initialize output pointer.
	op = 1

	do num_field = 1, nfields {
	    width = field_pos[num_field + 1] - field_pos[num_field]

	    if (num_field == xfield) {
	        call li_format_fieldd (xt, Memc[field], maxch, xformat,
		    nsdig_x, width, min_sigdigits)
	    } else if (num_field == yfield) {
		call li_format_fieldd (yt, Memc[field], maxch, yformat,
		    nsdig_y, width, min_sigdigits)
	    } else {
	        # Put "width" characters from inbuf into field
		call strcpy (inbuf[field_pos[num_field]], Memc[field], width)
	    }

	    # Fields must be delimited by at least one blank.
	    if (num_field > 1 && !IS_WHITE (Memc[field])) {
		outbuf[op] = ' '
		op = op + 1
	    }

	    # Copy "field" to output buffer.
	    op = op + gstrcpy (Memc[field], outbuf[op], maxch)
	}

	outbuf[op] = '\n'
	outbuf[op+1] = EOS

	call sfree (sp)
end


# LI_NPACK_LINE -- Fields are packed into the outbuf buffer.  Transformed
# fields are converted to strings; other fields are copied from
# the input line to output buffer.

procedure li_npack_lined (inbuf, outbuf, maxch, field_pos, nfields, 
	vfields, values, nsdigits, nvalues, vformats, sz_fmt, min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
int	field_pos[ARB]		#I starting positions for the fields
int	nfields			#I the number of fields
int	vfields[ARB]		#I the fields to be formatted
double	values[ARB]		#I the field values to be formatted
int	nsdigits[ARB]		#I the number of field significant digits
int	nvalues			#I the number of fields to be formatted
char	vformats[sz_fmt,ARB]	#I the field formats
int	sz_fmt			#I the size of the format string
int	min_sigdigits		#I the minimum number of significant digits

bool	found
int	op, num_field, num_var, width
pointer	sp, field
int	gstrcpy()

begin
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)

	# Initialize output pointer.
	op = 1

	do num_field = 1, nfields {
	    width = field_pos[num_field + 1] - field_pos[num_field]

	    found = false
	    do num_var = 1, nvalues {
	        if (num_field == vfields[num_var]) {
		    found = true
		    break
		}
	    }

	    if (found) {
	        call li_format_fieldd (values[num_var], Memc[field],
		    maxch, vformats[1,num_var], nsdigits[num_var], width,
		    min_sigdigits)
	    } else {
	        # Put "width" characters from inbuf into field
		call strcpy (inbuf[field_pos[num_field]], Memc[field], width)
	    }

	    # Fields must be delimited by at least one blank.
	    if (num_field > 1 && !IS_WHITE (Memc[field])) {
		outbuf[op] = ' '
		op = op + 1
	    }

	    # Copy "field" to output buffer.
	    op = op + gstrcpy (Memc[field], outbuf[op], maxch)
	}

	outbuf[op] = '\n'
	outbuf[op+1] = EOS

	call sfree (sp)
end


# LI_APPEND_LINE -- Fields are appened to the input buffer.  Transformed
# fields are converted to strings and added to the end of the input buffer.

procedure li_append_lined (inbuf, outbuf, maxch, xt, yt, xformat, yformat,
	nsdig_x, nsdig_y, min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
double	xt			#I the transformed x coordinate
double	yt			#I the transformed y coordinate
char	xformat[ARB]		#I the output format for the x column
char	yformat[ARB]		#I the output format for the y column
int	nsdig_x			#I the number of significant digits in x
int	nsdig_y			#I the number of significant digits in y
int	min_sigdigits		#I the minimum number of significant digits

int	ip, op
pointer	sp, field
int	gstrcpy()

begin
	# Allocate some working space.
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)

	# Copy the input buffer into the output buffer minus the newline.
	op = 1
	for (ip = 1; ip <= maxch; ip = ip + 1) {
	    if (inbuf[ip] == '\n' || inbuf[ip] == EOS)
		break
	    outbuf[op] = inbuf[ip]
	    op = op + 1
	}

	# Add two blanks.
	op = op + gstrcpy ("  ", outbuf[op], maxch - op + 1)

	# Format and add the the two extra fields with a blank between.
	call li_format_fieldd (xt, Memc[field], SZ_LINE, xformat,
	    nsdig_x, 0, min_sigdigits)
	op = op + gstrcpy (Memc[field], outbuf[op], maxch - op + 1)
	if (op <= maxch) {
	    outbuf[op] = ' '
	    op = op + 1
	}
	call li_format_fieldd (yt, Memc[field], SZ_LINE, yformat,
	    nsdig_y, 0, min_sigdigits)
	op = op + gstrcpy (Memc[field], outbuf[op], maxch - op + 1)

	# Add a newline.
	if (op <= maxch) {
	    outbuf[op] = '\n'
	    op = op + 1
	}
	outbuf[op] = EOS

	call sfree (sp)
end


# LI_NAPPEND_LINE -- Fields are appened to the input buffer.  Transformed
# fields are converted to strings and added to the end of the input buffer.

procedure li_nappend_lined (inbuf, outbuf, maxch, field_pos, nfields, 
	vfields, values, nsdigits, nvalues, vformats, sz_fmt, min_sigdigits)

char	inbuf[ARB]		#I the input string buffer
char	outbuf[maxch]		#O the output string buffer
int	maxch			#I the maximum size of the output buffer
int	field_pos[ARB]		#I starting positions for the fields
int	nfields			#I the number of fields
int	vfields[ARB]		#I the fields to be formatted
double	values[ARB]		#I the field values to be formatted
int	nsdigits[ARB]		#I the number of field significant digits
int	nvalues			#I the number of fields to be formatted
char	vformats[sz_fmt,ARB]	#I the field formats
int	sz_fmt			#I the size of the format string
int	min_sigdigits		#I the minimum number of significant digits

int	num_var, ip, op, index
pointer	sp, field, nvfields
int	gstrcpy()

begin
	# Allocate some working space.
	call smark (sp)
	call salloc (field, SZ_LINE, TY_CHAR)
	call salloc (nvfields, nvalues, TY_INT)
	do num_var = 1, nvalues
	    Memi[nvfields+num_var-1] = num_var
	call li_pqsorti (vfields, Memi[nvfields], Memi[nvfields], nvalues)

	# Copy the input buffer into the output buffer minus the newline.
	op = 1
	for (ip = 1; ip <= maxch; ip = ip + 1) {
	    if (inbuf[ip] == '\n' || inbuf[ip] == EOS)
		break
	    outbuf[op] = inbuf[ip]
	    op = op + 1
	}

	# Add two blanks.
	op = op + gstrcpy ("  ", outbuf[op], maxch - op + 1)

	do num_var = 1, nvalues {
	    index = Memi[nvfields+num_var-1]
	    call li_format_fieldd (values[index], Memc[field], SZ_LINE,
	        vformats[sz_fmt,index], nsdigits[index], 0, min_sigdigits)
	    op = op + gstrcpy (Memc[field], outbuf[op], maxch - op + 1)
	    if (num_var == nvalues) {
		if (op <= maxch) {
	    	    outbuf[op] = '\n'
	    	    op = op + 1
		}
	    } else {
		if (op <= maxch) {
	    	    outbuf[op] = ' '
	    	    op = op + 1
		}
	    }
	}

	outbuf[op] = EOS

	call sfree (sp)
end


# LI_FORMAT_FIELD -- A transformed coordinate is written into a string
# buffer.  The output field is of (at least) the same width and significance
# as the input list entry.

procedure li_format_fieldd (fval, wordbuf, maxch, format, nsdig, width,
	min_sigdigits)

double	fval			#I the input value to be formatted
char	wordbuf[maxch]		#O the output formatted string
int	maxch			#I the maximum length of the output string
char	format[ARB]		#I the output format
int	nsdig 			#I the number of sig-digits in current value
int	width			#I the width of the curent field
int	min_sigdigits		#I the minimum number of significant digits

int	fdigits, fwidth
begin
	if (format[1] == EOS) {
	    fdigits = max (min_sigdigits, nsdig)
	    fwidth = max (width, fdigits + 1)
	    call sprintf (wordbuf, maxch, "%*.*g")
	        call pargi (fwidth)
	        call pargi (fdigits)
	        call pargd (fval)
	} else {
	    call sprintf (wordbuf, maxch, format)
		call pargd (fval)
	}
end



