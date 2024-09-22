package tool

import "core:fmt"
import "core:strings"
import "core:os"
import "core:io"

DefineType :: proc(Writer : ^strings.Builder, BaseName, ClassName, FieldList : string)
{
	// Name:
	// ClassName :: struct
	strings.write_string(Writer, strings.concatenate([]string{ ClassName, " :: struct ", "\n{\n" }))

	// Fields
	Fields := strings.split(FieldList, ", ")
	for Field in Fields
	{
		strings.write_string(Writer, "    ")    
		strings.write_string(Writer, Field)
		strings.write_string(Writer, ",\n")
	}

	strings.write_string(Writer, "\n}\n")
}

DefineAST :: proc(OutputDir, BaseName : string, Types : []string)
{
	Strs := [?]string{ OutputDir, "\\", BaseName, ".odin" }
	Path := strings.concatenate(Strs[:])

	fmt.println(Path)

	Writer : strings.Builder

	strings.write_string(&Writer, "package main")
	strings.write_string(&Writer, "\n\n")
	strings.write_string(&Writer, "import \"core:fmt\"")
	strings.write_string(&Writer, "\n")
	strings.write_string(&Writer, "import \"core:os\"")
	strings.write_string(&Writer, "\n")
	strings.write_string(&Writer, "import \"core:strings\"")
	strings.write_string(&Writer, "\n\n")

	strings.write_string(&Writer, strings.concatenate([]string{ "ci", BaseName, " :: struct\n", "{\n" }[:]))

	for Type in Types
	{
		ClassName := strings.trim_space(strings.split(Type, ":")[0])
		Fields := strings.trim_space(strings.split(Type, ":")[1])

		DefineType(&Writer, "", ClassName, Fields)
		fmt.println(ClassName, Fields)
	}

	strings.write_string(&Writer, "}")

	fmt.println(strings.to_string(Writer))
}

main :: proc()
{
	Args := os.args

	if (len(Args) != 2)
	{
		fmt.println("Usage: generate_ast <output_dir>")
		os.exit(-1)
	}

	OutputDir := Args[1]

	DefineAST(Args[1], "Expr", []string{
		"Binary : Expr left, Token operator, Expr right",
		"Grouping : Expr expression",
		"Literal : object value",
		"Unary : Token operator, Expr right"
	})
}

