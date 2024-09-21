package main

ciScanner :: struct
{
	Source 	: string,
	Tokens 	: [dynamic]ciToken,
	Start 	: int,
	Current	: int,
	Line 	: int,
}

ciScanToken :: proc(Scanner : ^ciScanner) -> ciToken
{
	return ciToken{ ciTokenType.AND, "f", nil, 0 }
}

ciScanTokens :: proc(Scanner : ^ciScanner) -> []ciToken
{
	for !ciIsAtEnd(Scanner)
	{
		Scanner.Start = Scanner.Current;
		ciScanToken(Scanner);
	}

	NewToken := ciToken{ ciTokenType.EOF, "", nil, Scanner.Line }

	append(&Scanner.Tokens, NewToken)

	return (Scanner.Tokens[:])
}

ciIsAtEnd :: proc(Scanner : ^ciScanner) -> bool
{
	return Scanner.Current >= len(Scanner.Source)
}

