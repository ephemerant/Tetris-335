#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <string>
#include <ctype.h>

#include <windows.h>

#include "SDL/SDL.h"
#include "SDL/SDL_image.h"
#include "SDL/SDL_mixer.h"

extern "C" { FILE __iob_func[3] = { *stdin,*stdout,*stderr }; }

// Variables

int ticks = 0;
const int ticksPerFall = 1000;

int grid[20][10];

int piece[4][4];
int nextPiece[4][4];

int pieceX;
int pieceY;

bool rightDown = false;
bool leftDown = false;

bool titleScreen = true;
bool gameOver = false;

int rightDownTime = 0;
int leftDownTime = 0;

bool downDown = false;

// Prototypes

void update();

void init();
void beginGame();

void draw();

void drawImage(int x, int y, SDL_Surface* src, SDL_Surface* dest);
void drawGrid();

void drawPiece(int(&piece)[4][4], int pieceX, int pieceY);

void loadNextPiece();
void loadPieceType(int(&piece)[4][4], int color);

void rotatePiece(bool clockwise = true);

void moveX(int dir);
void moveY();

void projectPiece();
void clearRows();

bool collisionDetected();

// Variables (SDL)

SDL_Event event;

SDL_Surface *SCREEN;

SDL_Surface *TITLE_SCREEN;
SDL_Surface *GAME_OVER;

SDL_Surface *SQUARE_BLUE;
SDL_Surface *SQUARE_CYAN;
SDL_Surface *SQUARE_RED;
SDL_Surface *SQUARE_YELLOW;
SDL_Surface *SQUARE_ORANGE;
SDL_Surface *SQUARE_PURPLE;
SDL_Surface *SQUARE_GREEN;

SDL_Rect borderOuter;
SDL_Rect borderInner;

// Protypes (SDL)

SDL_Surface *LoadImage(std::string filename);

// Main

using namespace std;

int __stdcall WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	SCREEN = SDL_SetVideoMode(600, 600, 32, SDL_SWSURFACE);

	init();

	while (true)
	{
		update();

		while (SDL_PollEvent(&event))
		{
			if (titleScreen || gameOver)
			{
				// Handle keyboard events
				if (event.type == SDL_KEYDOWN)
				{
					switch (event.key.keysym.sym)
					{
					case SDLK_RETURN: // "ENTER" pressed
						titleScreen = false;
						gameOver = false;
						beginGame();
						break;
					}
				}
			}

			else
			{
				// Handle keyboard events
				if (event.type == SDL_KEYDOWN)
				{
					switch (event.key.keysym.sym)
					{
					case SDLK_UP: // "UP" pressed
						rotatePiece(); break;
					case SDLK_RIGHT: // "RIGHT" pressed
						rightDown = true; break;
					case SDLK_LEFT: // "LEFT" pressed
						leftDown = true; break;
					case SDLK_DOWN: // "DOWN" pressed
						downDown = true; break;
					}
				}
				else if (event.type == SDL_KEYUP)
				{
					switch (event.key.keysym.sym)
					{
					case SDLK_RIGHT: // "RIGHT" released
						rightDown = false;
						rightDownTime = 0;
						break;
					case SDLK_LEFT: // "LEFT" released
						leftDown = false;
						leftDownTime = 0;
						break;
					case SDLK_DOWN: // "DOWN" released
						downDown = false; break;
					}
				}
			}

			// "X" clicked
			if (event.type == SDL_QUIT)
			{
				return 0;
			}
		}
	}

	return 0;
}

void init()
{
	srand(time(NULL));

	// Set window text
	SDL_WM_SetCaption("Tetris", NULL);

	// Load screen images
	TITLE_SCREEN = LoadImage("img/title-screen.png");
	GAME_OVER = LoadImage("img/game-over.png");

	// Load pieces
	SQUARE_BLUE = LoadImage("img/blue.png");
	SQUARE_RED = LoadImage("img/red.png");
	SQUARE_GREEN = LoadImage("img/green.png");
	SQUARE_YELLOW = LoadImage("img/yellow.png");
	SQUARE_CYAN = LoadImage("img/cyan.png");
	SQUARE_PURPLE = LoadImage("img/purple.png");
	SQUARE_ORANGE = LoadImage("img/orange.png");

	// Set border
	borderInner.x = 200;
	borderInner.y = 100;
	borderInner.h = 400;
	borderInner.w = 200;

	borderOuter.x = borderInner.x - 10;
	borderOuter.y = borderInner.y - 10;
	borderOuter.h = borderInner.h + 10 * 2;
	borderOuter.w = borderInner.w + 10 * 2;

	beginGame();
}

void beginGame()
{
	loadPieceType(nextPiece, rand() % 7 + 1);

	loadNextPiece();

	// Reset arrays
	memset(grid, 0, sizeof(grid[0][0]) * 200);

	// Reset variables

	rightDown = false;
	leftDown = false;

	rightDownTime = 0;
	leftDownTime = 0;

	downDown = false;
}

void loadNextPiece()
{
	pieceX = 2;
	pieceY = -1;

	// Copy nextPiece into piece
	for (int y = 0; y < 4; y++)
		for (int x = 0; x < 4; x++)
			piece[y][x] = nextPiece[y][x];
	
	loadPieceType(nextPiece, rand() % 7 + 1);
}

void loadPieceType(int(&piece)[4][4], int color)
{
	memset(piece, 0, sizeof(piece[0][0]) * 16);

	switch (color)
	{
	case 1: // J
		piece[1][1] = color;
		piece[1][2] = color;
		piece[1][3] = color;
		piece[2][3] = color;
		break;
	case 2: // Z
		piece[1][1] = color;
		piece[1][2] = color;
		piece[2][2] = color;
		piece[2][3] = color;
		break;
	case 3: // S		
		piece[1][2] = color;
		piece[1][3] = color;
		piece[2][1] = color;
		piece[2][2] = color;
		break;
	case 4: // I
		piece[1][0] = color;
		piece[1][1] = color;
		piece[1][2] = color;
		piece[1][3] = color;
		break;
	case 5: // T		
		piece[1][1] = color;
		piece[1][2] = color;
		piece[1][3] = color;
		piece[2][2] = color;
		break;
	case 6: // O
		piece[1][1] = color;
		piece[1][2] = color;
		piece[2][1] = color;
		piece[2][2] = color;
		break;
	case 7: // L
		piece[1][1] = color;
		piece[1][2] = color;
		piece[1][3] = color;
		piece[2][1] = color;
		break;
	}
}

void rotatePiece(bool clockwise)
{
	// O (i.e. the "square") will never be rotated
	if (piece[1][1] == 6) return;

	int tempPiece[4][4];
	int backupPiece[4][4];

	bool firstRowCount = false;

	// Simple rotation
	for (int y = 0; y < 4; y++)
	{
		for (int x = 0; x < 4; x++)
		{
			if (clockwise)
			{
				tempPiece[x][3 - y] = piece[y][x];
				firstRowCount = firstRowCount || (x == 0 && piece[y][x] != 0);
			}
			else
			{
				tempPiece[y][x] = piece[x][3 - y];
				firstRowCount = firstRowCount || (y == 0 && tempPiece[y][x] != 0);
			}
			backupPiece[y][x] = piece[y][x];
		}
	}

	// If first row of the piece is empty, shift everything up by one
	if (!firstRowCount)
	{
		for (int y = 1; y < 4; y++)
		{
			for (int x = 0; x < 4; x++)
			{
				tempPiece[y - 1][x] = tempPiece[y][x];
				tempPiece[y][x] = 0;
			}
		}
	}

	// Copy back into piece
	for (int y = 0; y < 4; y++)
	{
		for (int x = 0; x < 4; x++)
		{
			piece[y][x] = tempPiece[y][x];
		}
	}

	// If collision, cancel rotation
	if (collisionDetected())
	{
		for (int y = 0; y < 4; y++)
		{
			for (int x = 0; x < 4; x++)
			{
				piece[y][x] = backupPiece[y][x];
			}
		}
	}
}

bool collisionDetected()
{
	for (int y = 0; y < 4; y++)
	{
		for (int x = 0; x < 4; x++)
		{
			if (!piece[y][x])
				continue;

			// Horizontal overlap with border
			if (pieceX + x > 9 || pieceX + x < 0)
				return true;

			// Vertical overlap with border
			if (pieceY + y > 19 || pieceY + y < 0)
				return true;

			// Collision with grid
			if (grid[y + pieceY][x + pieceX] != 0)
				return true;
		}
	}
	return false;
}

// Attempt to move the piece left or right
void moveX(int dir)
{
	pieceX += dir;

	if (collisionDetected())
		pieceX -= dir;
}

// Attempt to apply gravity to the piece
void moveY()
{
	pieceY++;

	if (collisionDetected())
	{
		pieceY--;
		projectPiece();
		clearRows();
		loadNextPiece();
		// Next piece immediately collides = Game Over
		if (collisionDetected())
			gameOver = true;
	}
}

// Project the piece onto the grid
void projectPiece()
{
	for (int y = 0; y < 4; y++)
	{
		for (int x = 0; x < 4; x++)
		{
			// Overwrite blank squares
			if (!grid[y + pieceY][x + pieceX])
				grid[y + pieceY][x + pieceX] = piece[y][x];
		}
	}
}

// Clear any full rows
void clearRows()
{
	int clears = 0;

	for (int y = 19; y >= 0; y--)
	{
		bool full = true;

		for (int x = 0; x < 10; x++)
		{
			if (!grid[y][x])
			{
				full = false;
				break;
			}
		}

		if (full)
		{
			// Shift everything down
			for (int y2 = y; y2 > 0; y2--)
			{
				for (int x = 0; x < 10; x++)
				{
					grid[y2][x] = grid[y2 - 1][x];
				}
			}
			y++;
		}
	}
}

// Handle gravity/graphics/movement
void update()
{
	// Clear everything
	SDL_FillRect(SCREEN, NULL, 0);

	if (titleScreen)
	{
		drawImage(50, 50, TITLE_SCREEN, SCREEN);
	}
	else if (gameOver)
	{
		drawImage(50, 50, GAME_OVER, SCREEN);
	}
	else
	{
		if (rightDown && !leftDown && !(rightDownTime++ % 300))
			moveX(1);
		else if (!rightDown && leftDown && !(leftDownTime++ % 300))
			moveX(-1);

		if (downDown)
			ticks += 14;

		if (++ticks > ticksPerFall)
		{
			moveY();
			ticks = 0;
		}

		draw();
	}

	// Refresh the screen
	SDL_Flip(SCREEN);
}

// graphics "master function"
void draw()
{
	// Draw grid border
	SDL_FillRect(SCREEN, &borderOuter, SDL_MapRGB(SCREEN->format, 0, 225, 255));
	SDL_FillRect(SCREEN, &borderInner, 0);

	// Draw blocks in the grid
	drawGrid();

	// Draw the piece
	drawPiece(piece, pieceX, pieceY);
	drawPiece(nextPiece, 12, 0);
}

void drawImage(int x, int y, SDL_Surface* src, SDL_Surface* dest)
{
	SDL_Rect offset;

	offset.x = x;
	offset.y = y;

	SDL_BlitSurface(src, NULL, dest, &offset);
}

void drawGrid()
{
	for (int y = 0; y < 20; y++)
	{
		for (int x = 0; x < 10; x++)
		{
			SDL_Surface *SQUARE_CURRENT = NULL;

			switch (grid[y][x])
			{
			case 1:
				SQUARE_CURRENT = SQUARE_BLUE; break;
			case 2:
				SQUARE_CURRENT = SQUARE_RED; break;
			case 3:
				SQUARE_CURRENT = SQUARE_GREEN; break;
			case 4:
				SQUARE_CURRENT = SQUARE_CYAN; break;
			case 5:
				SQUARE_CURRENT = SQUARE_PURPLE; break;
			case 6:
				SQUARE_CURRENT = SQUARE_YELLOW; break;
			case 7:
				SQUARE_CURRENT = SQUARE_ORANGE; break;
			}

			if (SQUARE_CURRENT != NULL)
				drawImage(x * 20 + borderInner.x, y * 20 + borderInner.y, SQUARE_CURRENT, SCREEN);
		}
	}
}

void drawPiece(int (&piece)[4][4], int pieceX, int pieceY)
{
	for (int y = 0; y < 4; y++)
	{
		for (int x = 0; x < 4; x++)
		{
			SDL_Surface *SQUARE_CURRENT = NULL;

			switch (piece[y][x])
			{
			case 1:
				SQUARE_CURRENT = SQUARE_BLUE; break;
			case 2:
				SQUARE_CURRENT = SQUARE_RED; break;
			case 3:
				SQUARE_CURRENT = SQUARE_GREEN; break;
			case 4:
				SQUARE_CURRENT = SQUARE_CYAN; break;
			case 5:
				SQUARE_CURRENT = SQUARE_PURPLE; break;
			case 6:
				SQUARE_CURRENT = SQUARE_YELLOW; break;
			case 7:
				SQUARE_CURRENT = SQUARE_ORANGE; break;
			}

			if (SQUARE_CURRENT != NULL)
				drawImage((x + pieceX) * 20 + borderInner.x, (y + pieceY) * 20 + borderInner.y, SQUARE_CURRENT, SCREEN);
		}
	}
}

SDL_Surface *LoadImage(string filename)
{
	SDL_Surface* LoadedImage = NULL;
	SDL_Surface* OptimizedImage = NULL;

	LoadedImage = IMG_Load(filename.c_str());

	if (LoadedImage != NULL)
	{
		OptimizedImage = SDL_DisplayFormat(LoadedImage);
		SDL_FreeSurface(LoadedImage);
	}

	return OptimizedImage;
}