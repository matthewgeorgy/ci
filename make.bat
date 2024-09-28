@echo off

if not exist bin\ (
	mkdir bin
)

odin build src -out:"bin/main.exe" -debug -thread-count:8
odin build tool -out:"bin/generate_ast.exe" -thread-count:8

