package main

import "core:strings"

ciParser :: struct
{
	Tokens	: []ciToken,
	Current	: int
}

ciParseError :: bool

ciCreateParser :: proc(Parser : ^ciParser, Tokens : []ciToken)
{
	Parser.Tokens = Tokens
	Parser.Current = 0
}

ciParser_Expression :: proc(Parser : ^ciParser) -> (^ciExpr, ciParseError)
{
	return ciParser_Equality(Parser)
}

ciParser_Equality :: proc(Parser : ^ciParser) -> (^ciExpr, ciParseError)
{
	Expr, Err := ciParser_Comparison(Parser)
	if !Err
	{
		return nil, false
	}

	for ciParser_Match(Parser, []ciTokenType{ ciTokenType.BANG_EQUAL, ciTokenType.EQUAL_EQUAL })
	{
		Operator := ciParser_Previous(Parser)
		Right, Err := ciParser_Comparison(Parser)
		if !Err
		{
			return nil, false
		}

		TempExpr := NewExpr(ciBinary)

		TempExpr.Left = Expr
		TempExpr.Operator = Operator
		TempExpr.Right = Right

		Expr = TempExpr
	}

	return Expr, true
}

ciParser_Match :: proc(Parser : ^ciParser, Types : []ciTokenType) -> bool
{
	for Type in Types
	{
		if (ciParser_Check(Parser, Type))
		{
			ciParser_Advance(Parser)

			return (true)
		}
	}

	return (false)
}

ciParser_Check :: proc(Parser : ^ciParser, Type : ciTokenType) -> bool
{
	if (ciParser_IsAtEnd(Parser))
	{
		return (false)
	}

	return (ciParser_Peek(Parser).Type == Type)
}

ciParser_Advance :: proc(Parser : ^ciParser) -> ciToken
{
	if (!ciParser_IsAtEnd(Parser))
	{
		Parser.Current += 1
	}

	return ciParser_Previous(Parser)
}

ciParser_IsAtEnd :: proc(Parser : ^ciParser) -> bool
{
	return (ciParser_Peek(Parser).Type == ciTokenType.EOF)
}

ciParser_Peek :: proc(Parser : ^ciParser) -> ciToken
{
	return (Parser.Tokens[Parser.Current])
}

ciParser_Previous :: proc(Parser : ^ciParser) -> ciToken
{
	return (Parser.Tokens[Parser.Current - 1])
}

ciParser_Comparison :: proc(Parser : ^ciParser) -> (^ciExpr, ciParseError)
{
	Expr, Err := ciParser_Term(Parser)
	if !Err
	{
		return nil, false
	}

	for (ciParser_Match(Parser, []ciTokenType{ ciTokenType.GREATER, ciTokenType.GREATER_EQUAL, ciTokenType.LESS, ciTokenType.LESS_EQUAL }))
	{
		Operator := ciParser_Previous(Parser)
		Right, Err := ciParser_Term(Parser);
		if !Err
		{
			return nil, false
		}

		TempExpr := NewExpr(ciBinary)

		TempExpr.Left = Expr
		TempExpr.Operator = Operator
		TempExpr.Right = Right

		Expr = TempExpr
	}

	return Expr, true
}

ciParser_Term :: proc(Parser : ^ciParser) -> (^ciExpr, ciParseError)
{
	Expr, Err := ciParser_Factor(Parser)
	if !Err
	{
		return nil, false
	}

	for (ciParser_Match(Parser, []ciTokenType{ ciTokenType.MINUS, ciTokenType.PLUS }))
	{
		Operator := ciParser_Previous(Parser)
		Right, Err := ciParser_Factor(Parser);
		if !Err
		{
			return nil, false
		}

		TempExpr := NewExpr(ciBinary)

		TempExpr.Left = Expr
		TempExpr.Operator = Operator
		TempExpr.Right = Right

		Expr = TempExpr
	}

	return Expr, Err
}

ciParser_Factor :: proc(Parser : ^ciParser) -> (^ciExpr, ciParseError)
{
	Expr, Err := ciParser_Unary(Parser)
	if !Err
	{
		return nil, false
	}

	for (ciParser_Match(Parser, []ciTokenType{ ciTokenType.SLASH, ciTokenType.STAR }))
	{
		Operator := ciParser_Previous(Parser)
		Right, Err := ciParser_Unary(Parser);
		if !Err
		{
			return nil, false
		}

		TempExpr := NewExpr(ciBinary)

		TempExpr.Left = Expr
		TempExpr.Operator = Operator
		TempExpr.Right = Right

		Expr = TempExpr
	}

	return Expr, Err
}

ciParser_Unary :: proc(Parser : ^ciParser) -> (^ciExpr, ciParseError)
{
	Expr : ^ciExpr

	if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.BANG, ciTokenType.MINUS }))
	{
		Operator := ciParser_Previous(Parser)
		Right, Err := ciParser_Unary(Parser);
		if !Err
		{
			return nil, false
		}

		Expr := NewExpr(ciUnary)

		Expr.Operator = Operator
		Expr.Right = Right

		return Expr, Err
	}
	else
	{
		return (ciParser_Primary(Parser))
	}
}

ciParser_Primary :: proc(Parser : ^ciParser) -> (^ciExpr, ciParseError)
{
	Expr : ^ciExpr
	Err : ciParseError = true

	if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.FALSE }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.Value = false
		Expr = TempExpr
	} else if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.TRUE }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.Value = true
		Expr = TempExpr
	} else if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.NIL }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.Value = nil
		Expr = TempExpr
	} else if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.NUMBER, ciTokenType.STRING }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.Value = ciParser_Previous(Parser).Literal
		Expr = TempExpr
	} else if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.LEFT_PAREN }))
	{
		TempExpr, Err := ciParser_Expression(Parser)
		if !Err
		{
			return nil, false
		}

		_, Err = ciParser_Consume(Parser, ciTokenType.RIGHT_PAREN, "Expected '(' after expression.");
		if (!Err)
		{
			return nil, false
		}

		TempExpr2 := NewExpr(ciGrouping)
		TempExpr2.Expression = TempExpr

		Expr = TempExpr2
	} else
	{
		ciError2(ciParser_Peek(Parser), "Expect expression.")
		Err = false
		Expr = nil
	}

	return Expr, Err
}

ciParser_Consume :: proc(Parser : ^ciParser, Type : ciTokenType, Message : string) -> (ciToken, ciParseError)
{
	Token : ciToken
	Err : ciParseError = true

	if (ciParser_Check(Parser, Type))
	{
		Token = ciParser_Advance(Parser)
	}
	else
	{
		Err = ciParser_Error(Parser, ciParser_Peek(Parser), Message)
	}

	return Token, Err
}

ciParser_Error :: proc(Parser : ^ciParser, Token : ciToken, Message : string) -> ciParseError
{
	ciError2(Token, Message)

	return false
}

ciParser_Synchronize :: proc(Parser : ^ciParser)
{
	ciParser_Advance(Parser)

	for (!ciParser_IsAtEnd(Parser))
	{
		if (ciParser_Previous(Parser).Type == ciTokenType.SEMICOLON)
		{
			return
		}

		#partial switch (ciParser_Peek(Parser).Type)
		{
			case ciTokenType.CLASS:
			case ciTokenType.FUN:
			case ciTokenType.VAR:
			case ciTokenType.FOR:
			case ciTokenType.IF:
			case ciTokenType.WHILE:
			case ciTokenType.PRINT:
			case ciTokenType.RETURN:
			{
				return
			}
		}

		ciParser_Advance(Parser)
	}
}

ciParser_Parse :: proc(Parser : ^ciParser) -> ^ciExpr
{
	 Expr, Err := ciParser_Expression(Parser)

	 if !Err
	 {
		 return nil
	 }

	 return Expr
}

