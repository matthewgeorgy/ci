package tool

import "core:fmt"
import "core:strings"
import "core:os"
import "core:io"

DefineType :: proc(Writer : ^strings.Builder, BaseName, ClassName, FieldList : string)
{
	Prefix := "ci"

	strings.write_string(Writer, strings.concatenate([]string{ Prefix, ClassName, " :: struct ", "\n{\n" }))

	// Fields
	Fields := strings.split(FieldList, ", ")
	for Field in Fields
	{
		Type := strings.trim_space(strings.split(Field, " ")[0])
		Name := strings.trim_space(strings.split(Field, " ")[1])

		strings.write_string(Writer, "    ")
		strings.write_string(Writer, Name)
		strings.write_string(Writer, " : ")
		strings.write_string(Writer, Prefix)
		strings.write_string(Writer, Type)
		strings.write_string(Writer, ",\n")
	}

	strings.write_string(Writer, "}\n\n")
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

	strings.write_string(&Writer, strings.concatenate([]string{ "ci", BaseName, " :: union\n", "{\n" }[:]))

	for Type in Types
	{
		ClassName := strings.trim_space(strings.split(Type, ":")[0])

		strings.write_string(&Writer, "    ^ci")
		strings.write_string(&Writer, ClassName)
		strings.write_string(&Writer, ",\n")
	}

	strings.write_string(&Writer, "}\n\n")

	for Type in Types
	{
		ClassName := strings.trim_space(strings.split(Type, ":")[0])
		Fields := strings.trim_space(strings.split(Type, ":")[1])

		DefineType(&Writer, "Expr", ClassName, Fields)
		fmt.println(ClassName, Fields)
	}

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
		"Literal : Object value",
		"Unary : Token operator, Expr right"
	})
}

