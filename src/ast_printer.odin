package main

import "core:fmt"
import "core:strings"

ciPrintExpr :: proc(Expr : ^ciExpr) -> string
{
	Parts := [dynamic]string{}

	switch V in Expr.variant
	{
		case ^ciBinary:
		{
			append(&Parts, "(assign ")
			append(&Parts, V.Operator.Lexeme)
			append(&Parts, " ")
			append(&Parts, ciPrintExpr(V.Left))
			append(&Parts, "(assign ")
			append(&Parts, ciPrintExpr(V.Right))
			append(&Parts, ")")
		}

		case ^ciGrouping:
		{
			append(&Parts, "(group ")
			append(&Parts, ciPrintExpr(V.Expression))
			append(&Parts, ")")
		}

		case ^ciLiteral:
		{
			switch Literal in V.Value
			{

				case f64:
				{
					append(&Parts, fmt.tprint(Literal))
				}
				case string:
				{
					append(&Parts, fmt.tprintf(`"%s"`, Literal))
				}

				case bool:
				{
					append(&Parts, fmt.tprintf("#%v", Literal))
				}

				case rawptr:
				{
					append(&Parts, "<nil>")
				}
			}
		}

		case ^ciUnary:
		{
			append(&Parts, "(")
			append(&Parts, V.Operator.Lexeme)
			append(&Parts, " ")
			append(&Parts, ciPrintExpr(V.Right))
			append(&Parts, ")")
		}
	}

	return strings.concatenate(Parts[:])
}

