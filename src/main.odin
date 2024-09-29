package main

import "core:fmt"
import "core:os"
import "core:strings"

// Globals
HadError : bool = false

// Functions
ciError :: proc(Line : int, Message : string)
{
	ciReport(Line, "", Message)
}

ciReport :: proc(Line : int, Where, Message : string)
{
	fmt.printf("[line %d] Error%s: %s\n", Line, Where, Message)
}

ciError2 :: proc(Token : ciToken, Message : string)
{
	if (Token.Type == ciTokenType.EOF)
	{
		ciReport(Token.Line, " at end", Message)
	}
	else
	{
		Strs := [?]string{ " at'", Token.Lexeme, "'" }


		ciReport(Token.Line, strings.concatenate(Strs[:]), Message)
	}
}


ciRun :: proc(Source : string)
{
	Scanner : ciScanner

	ciCreateScanner(&Scanner, Source)

	Tokens := ciScanner_ScanTokens(&Scanner)

	for Token in Tokens
	{
		fmt.println(Token)
	}
}

ciRunFile :: proc(Path : string)
{
	File : os.Handle
	Buff : [dynamic]byte
	Size : i64
	TotalRead : int

	File, _ = os.open(Path, os.O_RDONLY, 0)
	Size, _ = os.file_size(File)

	resize(&Buff, Size)

	TotalRead, _ = os.read(File, Buff[:])

	Source := string(Buff[:])

	ciRun(Source)
}

// Main
main :: proc()
{
	Args := os.args

	if (len(Args) > 2)
	{
		fmt.println("Usage: main [script]")
	}
	else if (len(Args) == 2)
	{
		fmt.println("Reading script: ", os.args[1])
		ciRunFile(os.args[1])
	}
	else
	{
		fmt.println("Reading prompt")
	}

	// Compound literal syntax!
	// Token := ciToken{ ciTokenType.AND, "foo", nil, 100 }
	// fmt.println(Token.Type, Token.Lexeme, Token.Literal, Token.Line)
}

