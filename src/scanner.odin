package main

import "core:strings"
import "core:strconv"

ciScanner :: struct
{
	Source 		: string,
	Tokens 		: [dynamic]ciToken,
	Start 		: int,
	Current		: int,
	Line 		: int,
	Keywords	: map[string]ciTokenType
}

ciCreateScanner :: proc(Scanner : ^ciScanner, Source : string)
{
	Scanner.Source = Source;
	Scanner.Start = 0;
	Scanner.Current = 0;
	Scanner.Line = 1;
	Scanner.Keywords = make(map[string]ciTokenType)

	Scanner.Keywords["and"]    = ciTokenType.AND
    Scanner.Keywords["class"]  = ciTokenType.CLASS
    Scanner.Keywords["else"]   = ciTokenType.ELSE
    Scanner.Keywords["false"]  = ciTokenType.FALSE
    Scanner.Keywords["for"]    = ciTokenType.FOR
    Scanner.Keywords["fun"]    = ciTokenType.FUN
    Scanner.Keywords["if"]     = ciTokenType.IF
    Scanner.Keywords["nil"]    = ciTokenType.NIL
    Scanner.Keywords["or"]     = ciTokenType.OR
    Scanner.Keywords["print"]  = ciTokenType.PRINT
    Scanner.Keywords["return"] = ciTokenType.RETURN
    Scanner.Keywords["super"]  = ciTokenType.SUPER
    Scanner.Keywords["this"]   = ciTokenType.THIS
    Scanner.Keywords["true"]   = ciTokenType.TRUE
    Scanner.Keywords["var"]    = ciTokenType.VAR
    Scanner.Keywords["while"]  = ciTokenType.WHILE
}

ciScanToken :: proc(Scanner : ^ciScanner)
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
		case '/':
		{
			if (ciMatch(Scanner, '/'))
			{
				for (ciPeek(Scanner) != '\n' && !ciIsAtEnd(Scanner))
				{
					ciAdvance(Scanner);
				}
			}
			else
			{
				ciAddToken(Scanner, ciTokenType.SLASH)
			}
		}

		case ' ':
		case '\t':
		case '\r':
		case '\n':
		{
			Scanner.Line += 1
		}

		case '"': { ciString(Scanner) }

		case:
		{ 
			if (ciIsDigit(C))
			{
				ciNumber(Scanner)
			}
			else if (ciIsAlpha(C))
			{
				ciIdentifier(Scanner)
			}
			else
			{
				ciError(Scanner.Line, "Unexpected cahracter.")
			}
		}
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

ciAddToken2 :: proc(Scanner : ^ciScanner, Type : ciTokenType, Literal : ciObject)
{
	Text := Scanner.Source[Scanner.Start:Scanner.Current]
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

ciPeek :: proc(Scanner : ^ciScanner) -> u8
{
	if (ciIsAtEnd(Scanner))
	{
		return (0)
	}

	return (Scanner.Source[Scanner.Current])
}

ciString :: proc(Scanner : ^ciScanner)
{
	for (ciPeek(Scanner) != '"' && !ciIsAtEnd(Scanner))
	{
		if (ciPeek(Scanner) == '\n')
		{
			Scanner.Line += 1
		}

		ciAdvance(Scanner)
	}

	if (ciIsAtEnd(Scanner))
	{
		ciError(Scanner.Line, "Unterminated String.")
	}

	ciAdvance(Scanner)

	Value := Scanner.Source[Scanner.Start + 1:Scanner.Current - 1]

	ciAddToken2(Scanner, ciTokenType.STRING, Value)
}

ciIsDigit :: proc(C : u8) -> bool
{
	return (C >= '0' && C <= '9')
}

ciNumber :: proc(Scanner : ^ciScanner)
{
	for (ciIsDigit(ciPeek(Scanner)))
	{
		ciAdvance(Scanner)
	}

	// Look for a fractional part
	if (ciPeek(Scanner) == '.' && ciIsDigit(ciPeekNext(Scanner)))
	{
		// Consume the .
		ciAdvance(Scanner)

		for (ciIsDigit(ciPeek(Scanner)))
		{
			ciAdvance(Scanner)
		}
	}

	Number := Scanner.Source[Scanner.Start:Scanner.Current]

	ciAddToken2(Scanner, ciTokenType.NUMBER, strconv.atof(Number))
}

ciPeekNext :: proc(Scanner : ^ciScanner) -> u8
{
	if (Scanner.Current + 1 >= len(Scanner.Source))
	{
		return (0)
	}

	return (Scanner.Source[Scanner.Current + 1])
}

ciIdentifier :: proc(Scanner : ^ciScanner)
{
	for (ciIsAlphaNumeric(ciPeek(Scanner)))
	{
		ciAdvance(Scanner)
	}

	Text := Scanner.Source[Scanner.Start:Scanner.Current]
	Type := Scanner.Keywords[Text]

	if (Type == nil)
	{
		Type = ciTokenType.IDENTIFIER
	}

	ciAddToken(Scanner, Type)
}

ciIsAlpha :: proc(C : u8) -> bool
{
	return ((C >= 'a' && C <= 'z') ||
		    (C >= 'A' && C <= 'Z') ||
	        (C == '_'))
		    
}

ciIsAlphaNumeric :: proc(C : u8) -> bool
{
	return (ciIsAlpha(C) || ciIsDigit(C))
}

