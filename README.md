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
		test eax, 1 ; First row empty
		jz @@ANDSHIFT
		jmp @@ENDIFSHIFT
	@@ANDSHIFT:
		test eax, 2 ; Second row empty
		jz @@THENSHIFT
		test eax, 4 ; Last row non-empty
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

#### Assembly Functions

* _MainCallBack
	* Input:  None
	* Result: Handles maintainence of game, including initializing, looping, and start/end handling.
* _GameLoop
	* Input:  None; Receives feedback from _GameTick regarding game status.
	* Result: Continues to run _GameTick function until it receives a 0 signaling game over.
* _GameTick
	* Input:  None; Receives feedback from SDL_GetTicks
	* Result: Handles game play movement and closing execution.
* _GetValueAt
	* Input:  Grid pointer, pieceX, pieceY, width
	* Result: Helper function to detect collision with walls and pieces already on the grid.
* _ClearArray
	* Input:  Piece pointer, length
	* Result: Sets piece's array to all 0's and effectively clears for next piece.
* _ShiftUp
	* Input:  A pointer
	* Result: Shifts row A up 1 and removes the bottom row. 
* _CopyPiece
	* Input:  A Pointer for piece, B Pointer for target
	* Result: Replicates A to B
* _ProjectPiece
	* Input:  Piece pointer, Grid pointer, PieceX coordinate, PieceY coordinate
	* Result: Project piece onto the game grid
* _CollisionDetected
	* Input:  Piece pointer, Grid pointer, PieceX coordinate, PieceY coordinate
	* Result: Returns true if collision occurs
* _RotatePiece
	* Input:  Piece pointer, Grid pointer, PieceX, PieceY
	* Result: Rotates piece 90 degrees
* _ClearRows
	* Input:  Grid pointer, Score pointer
	* Result: Clears full rows and awards points
* _LoadPieceType
	* Input:  Piece pointer, Color number
	* Result: Loads the chosen piece's configuration into piece pointer
* _BeginGame
	* Input: Piece pointer, Color number, Grid pointer, X pointer, Y Pointer, nextPiece pointer, Score pointer, downDown pointer, rightDown pointer, leftDown pointer, rightDownTime pointer, leftDownTime pointer
	* Result: Clears any past game results, resets all memory allocations and begins a new game
* _loadNextPiece
	* Input: X pointer, Y pointer, nextPiece pointer, Piece (current) pointer, Color number
	* Result: Generates the next piece and prepares it for the grid
* _moveX
	* Input: Direction number, Piece pointer, Grid pointer, PieceX pointer, PieceY pointer
	* Result: Checks for collision and shifts piece left or right
* _moveY
	* Input: Piece pointer, Grid pointer, PieceX pointer, PieceY pointer, gameOver pointer, nextPiece pointer, Color number, Score pointer
	* Result: Increases speed of fall, checks for collision then loads next piece
	
#### C++ Functions

* WinMain
	* Input:  HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow
	* Result: Calls _MainCallBack
* handleInput
	* Input:  None, watches for SDL_PollEvents
	* Result: Reacts to key presses 
* init
	* Input:  None
	* Result: Initializes game and sets image locations/screen dimensions/ etc
* update
	* Input:  None
	* Result: Handles gravity and resetting screen
* draw
	* Input:  None
	* Result: Handles grid and all graphics
* drawText
	* Input:  None
	* Result: Adds text to screen
* drawGridLines
	* Input:  None
	* Result: Adds grid lines to grid
* drawImage
	* Input:  X coordinate, Y coordinate, Source, Destination
	* Result: Adds images to grid
* drawGrid
	* Input:  None
	* Result: Adds gridlines to screen
* drawPiece
	* Input:  Piece pointer, PieceX coordinate, PieceY coordinate
	* Result: Adds piece to grid
* LoadImage
	* Input:  Filename
	* Result: Adds image file to SDL_Surface

## Problems & Solutions

#### Block Rotations

The general clockwise rotation of a 4x4 zero-indexed grid is a simple transformation of its coordinates (x, y) to (3-y, x).

In order to keep the pieces centered in their grids, if the first row is blank and either the second row is blank or the last row is not blank, everything is shifted up by one.

These methods combine to provide an algorithm that exactly follows the following image:

![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/shift-when.png)

*--Graphic by Clayton McGuire*

#### Smooth Controls

When playing a game, it is easy to take for granted smooth, intuitive controls. While implementing our controls, we realized this quickly. We began by having requiring one press per action, and holding the key down wouldn't do anything. We quickly found it tedious having to press the horizontal and down arrows multiple times for what should be a smooth action. Thus, we devised a plan to allow for holding down the keys while also keeping input crisp and expected.

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
