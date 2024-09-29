package main

ciExpr :: struct
{
	variant : union{^ciBinary, ^ciGrouping, ^ciLiteral, ^ciUnary}
}

ciBinary :: struct
{
	using e : ciExpr,

    Left : ^ciExpr,
    Operator : ciToken,
    Right : ^ciExpr,
}

ciGrouping :: struct
{
	using e : ciExpr,

    Expression : ^ciExpr,
}

ciLiteral :: struct
{
	using e : ciExpr,

    Value : ciObject,
}

ciUnary :: struct
{
	using e : ciExpr,

    Operator : ciToken,
    Right : ^ciExpr,
}

NewExpr :: proc($T : typeid) -> ^T
{
	E := new(T)

	E.variant = E

	return (E)
}

