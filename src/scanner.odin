package main

import "core:strings"

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
	C := ciAdvance(Scanner)

	switch (C)
	{
		case '(' : { ciAddToken(Scanner, ciTokenType.LEFT_PAREN) }
		case ')' : { ciAddToken(Scanner, ciTokenType.RIGHT_PAREN) }
		case '{' : { ciAddToken(Scanner, ciTokenType.LEFT_BRACE) }
		case '}' : { ciAddToken(Scanner, ciTokenType.RIGHT_BRACE) }
		case ',' : { ciAddToken(Scanner, ciTokenType.COMMA) }
		case '.' : { ciAddToken(Scanner, ciTokenType.DOT) }
		case '-' : { ciAddToken(Scanner, ciTokenType.MINUS) }
		case '+' : { ciAddToken(Scanner, ciTokenType.PLUS) }
		case ';' : { ciAddToken(Scanner, ciTokenType.SEMICOLON) }
		case '*' : { ciAddToken(Scanner, ciTokenType.STAR) }
		case '!' : { ciAddToken(Scanner, ciMatch(Scanner, '=') ? ciTokenType.BANG_EQUAL : ciTokenType.BANG) }
		case '=' : { ciAddToken(Scanner, ciMatch(Scanner, '=') ? ciTokenType.EQUAL_EQUAL : ciTokenType.EQUAL) }
		case '<' : { ciAddToken(Scanner, ciMatch(Scanner, '=') ? ciTokenType.LESS_EQUAL : ciTokenType.LESS) }
		case '>' : { ciAddToken(Scanner, ciMatch(Scanner, '=') ? ciTokenType.GREATER_EQUAL : ciTokenType.GREATER) }

		case     : { ciError(Scanner.Line, "Unexpected cahracter.") }
	}

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
	return (Scanner.Current >= len(Scanner.Source))
}

ciAdvance :: proc(Scanner : ^ciScanner) -> u8
{
	C := Scanner.Source[Scanner.Current]
	Scanner.Current += 1

	return (C)
}

ciAddToken :: proc(Scanner : ^ciScanner, Type : ciTokenType)
{
	ciAddToken2(Scanner, Type, nil)
}

ciAddToken2 :: proc(Scanner : ^ciScanner, Type : ciTokenType, Literal : rawptr)
{
	Text := strings.substring(Scanner.Source, Scanner.Start, Scanner.Current)
	Token := ciToken{ Type, Text, Literal, Scanner.Line}

	append(&Scanner.Tokens, Token)
}

ciMatch :: proc(Scanner : ^ciScanner, Exepected : u8) -> bool
{
	if (ciIsAtEnd(Scanner))
	{
		return (false)
	}

	if (Scanner.Source[Scanner.Current] != Exepected)
	{
		return (false)
	}

	Scanner.Current += 1

	return (true)
}

