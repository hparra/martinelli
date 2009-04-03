init:
	high 0
	pause 100
	
main:
	serin 3, T2400, b0 ; BLOCKS - Read command
	;if b0 = "G" then get_data
	if b0 = "S" then stream_data
	if b0 = "V" then version
	goto main

; Outputs Name and Version
version:
	serout 0, T2400, ("SimpleScale 1.0", 13, 10)
	goto main

stream_data:
	; FIXME: Subroutine this.
	w4=0
	for b13 = 0 to 4
		readadc 1, b12
		readadc 2, b11
		w4 = w4 + b12 + b11
		readadc 1, b12
		readadc 2, b11
		w4 = w4 + b12 + b11
	next
	w4 = w4 / 20
	w4= 102 * w4 / 100	
	if w4 < 30 then
		w4 = 0
	else 
		w4 = w4 -17
	endif	
	serout 0, T2400, (#w4, 13, 10)		
	goto stream_data