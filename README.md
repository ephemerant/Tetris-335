# Tetris

## Table of Contents

1. [Introduction](#introduction)
1. [Background](#background)
1. [Code](#code)
1. [Documentation](#documentation)
1. [Problems & Solutions](#problems--solutions)
1. [Future Work](#future-work)
1. [Conclusions](#conclusions)
1. [User Manual](#user-manual)

## Introduction

This project was a collaboration between [Clayton McGuire]() and [Chris Loos]() for the [Computer Structures](http://www.soic.indiana.edu/undergraduate/courses/index.html?number=c335&department=csci) class at IUS.

The general requirements were:

1. Create a game
1. The majority of it had to be programmed in Assembly

We chose to recreate Tetris because it deals with a variety of algorithms (rotatation, projection, collision, etc.) that provide just enough mental stimulation without being a huge pain to implement.  It was also something that we had always wanted to recreate in the past but had never gotten around to doing.

While MASM is a powerful language, the number of commands necessary to implement the same steps as C++ and other higher languages makes the process of translating extensive and laborous. Since MASM does not handle graphics, C++ was essential in creating a functional GUI for users to interact with the game. Those obstacles intrigued and inspired us to utilize these languages to implement a classic Tetris game.

## Background

![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/alexey.png)

> In 1984, Alexey Pajitnov was diligently programming computer games that tested the capabilities of new equipment developed by the USSR. In his spare time, he drew inspiration from his favorite puzzle board game, Pentominos, and decided to create a computer game for himself. Pajitnov envisioned an electronic game that let players arrange puzzle pieces in real time as they fell from the top of the playing field. The resulting design was a game that used seven distinctive geometric playing pieces, each made up of four squares. Pajitnov called this game “Tetris,” a combination of “tetra” (the Greek word meaning “four”) and “tennis” (his favorite sport).

*--[Tetris.com](http://tetris.com/about-tetris/)*

## Code

The [first prototype of the game](https://github.com/ephemerant/Tetris) was developed in C# as a proof-of-concept. We then took the time to familiarize ourselves with C++ and the SDL library. After ironing out the game in C++, we began rewriting our functions in Assembly. We learned a lot along the way about Tetris, SDL, linear algebra, and the meaning of life.

As an example, here's our rotation algorithm in C#:

```C#
public bool rotate(int[,] grid)
{
    int tmpIndex = index;

    index -= 1;

    if (index < 0)
        index = rotations.Count - 1;

    if (!collidesWith(grid))                
        return true;

    // Restore index
    index = tmpIndex;
    return false;
}
```

We went the object oriented route and viewed pieces as objects with varying rotational states hard-coded in. We wanted to generalize rotation and break away from hard-coding so as to make the transition into Assembly a little easier. After some thought, we came up with a rotation algorithm in C++ that we were happy with.

```C++
void rotatePiece() {
	int tempPiece[4][4];

	bool firstRowCount = false;
	bool secondRowCount = false;
	bool lastRowCount = false;

	// Simple clockwise rotation
	for (int y = 0; y < 4; y++) {
		for (int x = 0; x < 4; x++) {
			tempPiece[x][3 - y] = piece[y][x];

			firstRowCount = firstRowCount || (x == 0 && piece[y][x] != 0);
			secondRowCount = secondRowCount || (x == 1 && piece[y][x] != 0);
			lastRowCount = lastRowCount || (x == 3 && piece[y][x] != 0);
		}
	}
	// If first row of the piece is empty and the second row is empty or the last row isn't empty, shift everything up by one
	if (!firstRowCount && (!secondRowCount || lastRowCount)) {
		for (int y = 1; y < 4; y++) {
			for (int x = 0; x < 4; x++) {
				tempPiece[y - 1][x] = tempPiece[y][x];
				tempPiece[y][x] = 0;
			}
		}
	}
	// If the new piece doesn't collide with anything, copy back into the original
	if (!collisionDetected(tempPiece))
		for (int y = 0; y < 4; y++)
			for (int x = 0; x < 4; x++)
				piece[y][x] = tempPiece[y][x];
}
```

While it is bulkier, it does save having to hard-code all of the states for the seven pieces.

Translated into Assembly, we ended up breaking apart the rotations and shifts into two different methods. The rotation code now returns a set of bits indicating which rows are non-empty.

Here is the reduced C++ code that now uses our external Assembly methods (indicated with leading underscores):

```C++
void rotatePiece() {
	int tempPiece[4][4];

	int rowCounts = _RotateClockwise(&piece, &tempPiece);
	
	// If first row of the piece is empty and the second row is empty or the last row isn't empty, shift everything up by one
	if (!(rowCounts & 1) && (!(rowCounts & 2) || (rowCounts & 4)))
		_ShiftUp(&tempPiece);

	// If the new piece doesn't collide with anything, copy back into the original
	if (!collisionDetected(tempPiece))
		_CopyPiece(&tempPiece, &piece);
}
```

Our final step was to completey move this block of code to Assembly. After doing so, we ended up with the following:

```ASM
_RotatePiece PROC, piece:PTR DWORD, grid:PTR DWORD, pieceX:DWORD, pieceY:DWORD
	invoke _RotateClockwise, piece, OFFSET TempPiece

	@@IFSHIFT:
		test eax, 1 ; First row
		jz @@ANDSHIFT
		jmp @@ENDIFSHIFT
	@@ANDSHIFT:
		test eax, 2 ; Second row
		jz @@THENSHIFT
		jmp @@ORSHIFT
	@@ORSHIFT:
		test eax, 4 ; Last row
		jnz @@THENSHIFT
		jmp @@ENDIFSHIFT
	@@THENSHIFT:
		invoke _ShiftUp, OFFSET TempPiece
	@@ENDIFSHIFT:

	@@IFCOLLISION:
		invoke _CollisionDetected, OFFSET TempPiece, grid, pieceX, pieceY
		cmp eax, 0
		jz @@THENCOLLISION
		jmp @@ENDIFCOLLISION
	@@THENCOLLISION:
		invoke _CopyPiece, OFFSET TempPiece, piece
	@@ENDIFCOLLISION:
	ret
_RotatePiece ENDP
```

## Documentation

Function descriptions are in the works.

#### Assembly Functions

* _MainCallBack
* _GameLoop
* _GameTick
* _GetValueAt
* _ClearArray
* _ShiftUp
* _RotateClockwise
* _CopyPiece
* _ProjectPiece
* _CollisionDetected
* _RotatePiece
* _ClearRows
* _LoadPieceType

#### C++ Functions

* WinMain
* handleInput
* init
* beginGame
* loadNextPiece
* moveX
* moveY
* clearRows
* update
* draw
* drawText
* drawGridLines
* drawImage
* drawGrid
* drawPiece
* LoadImage

## Problems & Solutions

#### Block Rotations

The general clockwise rotation of a 4x4 zero-indexed grid is a simple transformation of its coordinates (x, y) to (3-y, x).

In order to keep the pieces centered in their grids, if the first row is blank and either the second row is blank or the last row is not blank, everything is shifted up by one.

These methods combine to provide an algorithm that exactly follows the following image:

![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/shift-when.png)

*--Graphic by Clayton McGuire*

#### Smooth Controls

## Future Work

#### Likely to add:

* Full screen
* Gamepad support
* Level progression
* Pause

#### Would like to add, but not likely:

* AI that can play for you

## Conclusions

In conclusion, we're happy with what we've accomplished and what we've gotten out of the project. We've ended up with what we believe to be a fairly fun, interesting creation that is built using languages that the both of us had little experience with coming in.

While MASM was initially a challenge, overcoming that challenge strengthened our understanding of both languages involved and our fundamental understanding of the interaction between coding and hardware. By working at the raw memory level our appreciation for the behind the scenes maintenance involved with higher level languages vastly grew and explained many of the nuances we have encountered along the way.

## User Manual

The user is initially prompted to press enter to begin.

![](https://github.com/ephemerant/Tetris-335/blob/master/img/title-screen.png)

You control a falling tetromino that can be manipulated via the following keys:

**Left/Right:** Move the piece to the left and right

**Up:** Rotate the piece clockwise

**Down:** Make the piece fall faster

Your goal is to neatly stack the pieces and fill in any gaps in the resulting rows. Any filled rows are cleared, freeing up room for your unlimited supply of tetrominos. You will receive points for each clear, and you will receive more points if you clear more rows at a time.

![](https://github.com/ephemerant/Tetris-335/blob/master/img/TetrisInAction.png)

Once the screen has filled with tetronimos, the game has ended and must be restarted.

![](https://github.com/ephemerant/Tetris-335/blob/master/img/game-over.png)
