init:
	high 0
	pause 100
main:

	;serin 3, T2400, b0 ; BLOCKS - Read command
	;if b0 = "G" then get_data
	;if b0 = "S" then stream_data
	;if b0 = "V" then version
	;goto main
	goto stream_data

; Outputs Name and Version
version:
	serout 0, T2400, ("SimpleAccelerometer 1.0", 13, 10)
	goto main

; Gets data value
get_data:
	readadc 2, b12
	serout 0, T2400, (#b12, 13, 10)
	goto main

; streams data values. infinite loop.	
stream_data:
	readadc 2, b12
	serout 0, T2400, (#b12, 13, 10)
	pause 100
	goto stream_data
