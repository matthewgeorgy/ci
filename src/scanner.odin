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

ciScanner_ScanToken :: proc(Scanner : ^ciScanner)
{
	C := ciScanner_Advance(Scanner)

	switch (C)
	{
		case '(' : { ciScanner_AddToken(Scanner, ciTokenType.LEFT_PAREN) }
		case ')' : { ciScanner_AddToken(Scanner, ciTokenType.RIGHT_PAREN) }
		case '{' : { ciScanner_AddToken(Scanner, ciTokenType.LEFT_BRACE) }
		case '}' : { ciScanner_AddToken(Scanner, ciTokenType.RIGHT_BRACE) }
		case ',' : { ciScanner_AddToken(Scanner, ciTokenType.COMMA) }
		case '.' : { ciScanner_AddToken(Scanner, ciTokenType.DOT) }
		case '-' : { ciScanner_AddToken(Scanner, ciTokenType.MINUS) }
		case '+' : { ciScanner_AddToken(Scanner, ciTokenType.PLUS) }
		case ';' : { ciScanner_AddToken(Scanner, ciTokenType.SEMICOLON) }
		case '*' : { ciScanner_AddToken(Scanner, ciTokenType.STAR) }
		case '!' : { ciScanner_AddToken(Scanner, ciScanner_Match(Scanner, '=') ? ciTokenType.BANG_EQUAL : ciTokenType.BANG) }
		case '=' : { ciScanner_AddToken(Scanner, ciScanner_Match(Scanner, '=') ? ciTokenType.EQUAL_EQUAL : ciTokenType.EQUAL) }
		case '<' : { ciScanner_AddToken(Scanner, ciScanner_Match(Scanner, '=') ? ciTokenType.LESS_EQUAL : ciTokenType.LESS) }
		case '>' : { ciScanner_AddToken(Scanner, ciScanner_Match(Scanner, '=') ? ciTokenType.GREATER_EQUAL : ciTokenType.GREATER) }
		case '/':
		{
			if (ciScanner_Match(Scanner, '/'))
			{
				for (ciScanner_Peek(Scanner) != '\n' && !ciScanner_IsAtEnd(Scanner))
				{
					ciScanner_Advance(Scanner);
				}
			}
			else
			{
				ciScanner_AddToken(Scanner, ciTokenType.SLASH)
			}
		}

		case ' ':
		case '\t':
		case '\r':
		case '\n':
		{
			Scanner.Line += 1
		}

		case '"': { ciScanner_String(Scanner) }

		case:
		{ 
			if (ciIsDigit(C))
			{
				ciScanner_Number(Scanner)
			}
			else if (ciIsAlpha(C))
			{
				ciScanner_Identifier(Scanner)
			}
			else
			{
				ciError(Scanner.Line, "Unexpected cahracter.")
			}
		}
	}

}

ciScanner_ScanTokens :: proc(Scanner : ^ciScanner) -> []ciToken
{
	for !ciScanner_IsAtEnd(Scanner)
	{
		Scanner.Start = Scanner.Current;
		ciScanner_ScanToken(Scanner);
	}

	NewToken := ciToken{ ciTokenType.EOF, "", nil, Scanner.Line }

	append(&Scanner.Tokens, NewToken)

	return (Scanner.Tokens[:])
}

ciScanner_IsAtEnd :: proc(Scanner : ^ciScanner) -> bool
{
	return (Scanner.Current >= len(Scanner.Source))
}

ciScanner_Advance :: proc(Scanner : ^ciScanner) -> u8
{
	C := Scanner.Source[Scanner.Current]
	Scanner.Current += 1

	return (C)
}

ciScanner_AddToken :: proc(Scanner : ^ciScanner, Type : ciTokenType)
{
	ciScanner_AddToken2(Scanner, Type, nil)
}

ciScanner_AddToken2 :: proc(Scanner : ^ciScanner, Type : ciTokenType, Literal : ciObject)
{
	Text := Scanner.Source[Scanner.Start:Scanner.Current]
	Token := ciToken{ Type, Text, Literal, Scanner.Line}

	append(&Scanner.Tokens, Token)
}

ciScanner_Match :: proc(Scanner : ^ciScanner, Exepected : u8) -> bool
{
	if (ciScanner_IsAtEnd(Scanner))
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

ciScanner_Peek :: proc(Scanner : ^ciScanner) -> u8
{
	if (ciScanner_IsAtEnd(Scanner))
	{
		return (0)
	}

	return (Scanner.Source[Scanner.Current])
}

ciScanner_String :: proc(Scanner : ^ciScanner)
{
	for (ciScanner_Peek(Scanner) != '"' && !ciScanner_IsAtEnd(Scanner))
	{
		if (ciScanner_Peek(Scanner) == '\n')
		{
			Scanner.Line += 1
		}

		ciScanner_Advance(Scanner)
	}

	if (ciScanner_IsAtEnd(Scanner))
	{
		ciError(Scanner.Line, "Unterminated String.")
	}

	ciScanner_Advance(Scanner)

	Value := Scanner.Source[Scanner.Start + 1:Scanner.Current - 1]

	ciScanner_AddToken2(Scanner, ciTokenType.STRING, Value)
}

ciIsDigit :: proc(C : u8) -> bool
{
	return (C >= '0' && C <= '9')
}

ciScanner_Number :: proc(Scanner : ^ciScanner)
{
	for (ciIsDigit(ciScanner_Peek(Scanner)))
	{
		ciScanner_Advance(Scanner)
	}

	// Look for a fractional part
	if (ciScanner_Peek(Scanner) == '.' && ciIsDigit(ciScanner_PeekNext(Scanner)))
	{
		// Consume the .
		ciScanner_Advance(Scanner)

		for (ciIsDigit(ciScanner_Peek(Scanner)))
		{
			ciScanner_Advance(Scanner)
		}
	}

	Number := Scanner.Source[Scanner.Start:Scanner.Current]

	ciScanner_AddToken2(Scanner, ciTokenType.NUMBER, strconv.atof(Number))
}

ciScanner_PeekNext :: proc(Scanner : ^ciScanner) -> u8
{
	if (Scanner.Current + 1 >= len(Scanner.Source))
	{
		return (0)
	}

	return (Scanner.Source[Scanner.Current + 1])
}

ciScanner_Identifier :: proc(Scanner : ^ciScanner)
{
	for (ciIsAlphaNumeric(ciScanner_Peek(Scanner)))
	{
		ciScanner_Advance(Scanner)
	}

	Text := Scanner.Source[Scanner.Start:Scanner.Current]
	Type := Scanner.Keywords[Text]

	if (Type == nil)
	{
		Type = ciTokenType.IDENTIFIER
	}

	ciScanner_AddToken(Scanner, Type)
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

