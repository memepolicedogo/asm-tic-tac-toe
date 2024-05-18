#! /bin/bash
nasm -f elf64 -g -F dwarf tictactoe.asm && ld -o tictactoe tictactoe.o

