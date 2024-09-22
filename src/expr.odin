package main

ciExpr :: struct
{
	Internal : rawptr
}

ciBinary :: struct
{
	Left 		: ciExpr,
	Right 		: ciExpr,
	Operator	: ciToken
}

