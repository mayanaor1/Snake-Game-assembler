# Snake-Game-assembler
## Description
This assembly code implements a game where the player moves around the screen collecting points. The game uses the 80x25 text mode screen and keyboard input for player movement.
## Features

Player movement using WASD keys

Random point generation

Score tracking

Timer-based interrupt handling

How to Play

Use the following keys to move the player:

W: Move up
A: Move left
S: Move down
D: Move right


Collect points (displayed as hearts) by moving the player over them
Press Q to quit the game and display the final score

Technical Details

The code is written in x86 assembly for DOS
It uses interrupt handling to manage game timing
The game screen is managed using direct video memory access

Building and Running
To assemble and run this code, you'll need:

An x86 assembler (e.g., MASM, TASM)
A DOS environment or DOS emulator (e.g., DOSBox)

Assembly and linking commands may vary depending on your assembler. Please refer to your assembler's documentation for specific instructions.
Authors

Maya Naor (315176362)
Adina Hessen (336165139)

Date
September 6, 2022
Notes

This code is designed to run in a 16-bit DOS environment
It modifies interrupt vectors, so use caution when running in a real DOS environment
