package main

ciExpr :: struct
{
	variant : union{^ciBinary, ^ciGrouping, ^ciLiteral, ^ciUnary}
}

ciBinary :: struct
{
	using e : ciExpr,

    left : ^ciExpr,
    operator : ciToken,
    right : ^ciExpr,
}

ciGrouping :: struct
{
	using e : ciExpr,

    expression : ^ciExpr,
}

ciLiteral :: struct
{
	using e : ciExpr,

    value : ciObject,
}

ciUnary :: struct
{
	using e : ciExpr,

    operator : ciToken,
    right : ^ciExpr,
}

NewExpr :: proc($T : typeid) -> ^T
{
	E := new(T)

	E.variant = E

	return (E)
}

