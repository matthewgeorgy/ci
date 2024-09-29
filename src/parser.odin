package main

import "core:strings"

ciParser :: struct
{
	Tokens	: [dynamic]ciToken,
	Current	: int
}

ciParserError :: struct
{
	Value : int
}

ciCreateParser :: proc(Parser : ^ciParser, Tokens : [dynamic]ciToken)
{
	Parser.Tokens = Tokens
	Parser.Current = 0
}

ciParser_Expression :: proc(Parser : ^ciParser) -> ^ciExpr
{
	return (ciParser_Equality(Parser))
}

ciParser_Equality :: proc(Parser : ^ciParser) -> ^ciExpr
{
	Expr := ciParser_Comparison(Parser)

	for ciParser_Match(Parser, []ciTokenType{ ciTokenType.BANG_EQUAL, ciTokenType.EQUAL_EQUAL })
	{
		Operator := ciParser_Previous(Parser)
		Right := ciParser_Comparison(Parser)

		TempExpr := NewExpr(ciBinary)

		TempExpr.left = Expr
		TempExpr.operator = Operator
		TempExpr.right = Right

		Expr = TempExpr
	}

	return (Expr)
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

ciParser_Comparison :: proc(Parser : ^ciParser) -> ^ciExpr
{
	Expr := ciParser_Term(Parser)

	for (ciParser_Match(Parser, []ciTokenType{ ciTokenType.GREATER, ciTokenType.GREATER_EQUAL, ciTokenType.LESS, ciTokenType.LESS_EQUAL }))
	{
		Operator := ciParser_Previous(Parser)
		Right := ciParser_Term(Parser);

		TempExpr := NewExpr(ciBinary)

		TempExpr.left = Expr
		TempExpr.operator = Operator
		TempExpr.right = Right

		Expr = TempExpr
	}

	return (Expr)
}

ciParser_Term :: proc(Parser : ^ciParser) -> ^ciExpr
{
	Expr := ciParser_Factor(Parser)

	for (ciParser_Match(Parser, []ciTokenType{ ciTokenType.MINUS, ciTokenType.PLUS }))
	{
		Operator := ciParser_Previous(Parser)
		Right := ciParser_Factor(Parser);

		TempExpr := NewExpr(ciBinary)

		TempExpr.left = Expr
		TempExpr.operator = Operator
		TempExpr.right = Right

		Expr = TempExpr
	}

	return (Expr)
}

ciParser_Factor :: proc(Parser : ^ciParser) -> ^ciExpr
{
	Expr := ciParser_Unary(Parser)

	for (ciParser_Match(Parser, []ciTokenType{ ciTokenType.SLASH, ciTokenType.STAR }))
	{
		Operator := ciParser_Previous(Parser)
		Right := ciParser_Unary(Parser);

		TempExpr := NewExpr(ciBinary)

		TempExpr.left = Expr
		TempExpr.operator = Operator
		TempExpr.right = Right

		Expr = TempExpr
	}

	return (Expr)
}

ciParser_Unary :: proc(Parser : ^ciParser) -> ^ciExpr
{
	for (ciParser_Match(Parser, []ciTokenType{ ciTokenType.SLASH, ciTokenType.STAR }))
	{
		Operator := ciParser_Previous(Parser)
		Right := ciParser_Unary(Parser);

		Expr := NewExpr(ciUnary)

		Expr.operator = Operator
		Expr.right = Right

		return (Expr)
	}

	return (ciParser_Primary(Parser))
}

ciParser_Primary :: proc(Parser : ^ciParser) -> ^ciExpr
{
	Expr : ^ciExpr

	if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.FALSE }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.value = false
		Expr = TempExpr
	}

	if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.TRUE }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.value = true
		Expr = TempExpr
	}

	if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.NIL }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.value = nil
		Expr = TempExpr
	}

	if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.NUMBER, ciTokenType.STRING }))
	{
		TempExpr := NewExpr(ciLiteral)
		TempExpr.value = ciParser_Previous(Parser).Literal
		Expr = TempExpr
	}

	if (ciParser_Match(Parser, []ciTokenType{ ciTokenType.LEFT_PAREN }))
	{
		TempExpr := ciParser_Expression(Parser)

		ciParser_Consume(Parser, ciTokenType.RIGHT_PAREN, "Expected '(' after expression.");

		TempExpr2 := NewExpr(ciGrouping)
		TempExpr2.expression = TempExpr

		Expr = TempExpr2
	}

	return (Expr)
}

ciParser_Consume :: proc(Parser : ^ciParser, Type : ciTokenType, Message : string) -> (ciToken, ciParserError)
{
	Token : ciToken
	Err : ciParserError

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

ciParser_Error :: proc(Parser : ^ciParser, Token : ciToken, Message : string) -> ciParserError
{
	ciError2(Token, Message)
	Err : ciParserError = { 1 }

	return Err
}

