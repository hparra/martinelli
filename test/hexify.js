/*
 * Hexify.js
 * 
 * Hector G. Parra
 */

/**
 * Takes an even numbered ASCII string and converts doublets into appropriate ASCII character to form an ASCII string of literal hexidecimal numbers. As a result, strings may not be printable. Returns null if param was invalid.
 * 
 * @param Even length ASCII String
 * @return Even length hexified String
 * @type String
 * @author Hector G. Parra
 */
function hexify(s) {
	s = s.split(' ').join(''); // eliminate spaces
	if (s.length % 2)
		return null; // not an even numbered string
	s = s.split(/([0-9a-fA-F]{2})/); // FIXME: Above regex returns unwanted ""s
	// FIXME: because of nature of split, this may return trash, so it doesn't really check anything
	r = "";
	for (i in s)
		if (s[i] != "")
			r += String.fromCharCode(parseInt(s[i], 16));
	return r;
}

function test_hexify(s) {
	alert("Original: " + s);
	s = s.split(' ').join(''); // eliminate spaces
	alert("Spaces removed: " + s);
	l = s.length;
	if (l % 2)
		return null; // not an even numbered string
	s = s.split(/([0-9a-fA-F]{2})/);
	alert("after split: " + s);
	for (i in s)
		if (s[i] == "")
			s.splice(i,1);
	alert("Split into verified doublets: " + s);
	//if (s.length != l / 2)
	//	return null; // did not parse to correct # of doublets
	for (i in s)
		s[i] = parseInt(s[i], 16);
	alert("Doublets as ints: " + s);
	
	// fromCharCode doesn't accept array
	//return String.fromCharCode(s.join(','));
	r = "";
	for (i in s)
		r += String.fromCharCode(s[i]);
	alert("Hexified: " + r);
	return r;
}