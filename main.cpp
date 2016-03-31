#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <string>
#include <ctype.h>

#include "SDL/SDL.h"
#include "SDL/SDL_image.h"
#include "SDL/SDL_mixer.h"

extern "C" { FILE __iob_func[3] = { *stdin,*stdout,*stderr }; }

// Variables

int ticks = 0;
const int ticksPerFall = 1200;

int grid[20][10];
int piece[4][4];

int pieceX;
int pieceY;

bool rightDown = false;
bool leftDown = false;

int rightDownTime = 0;
int leftDownTime = 0;

bool downDown = false;

// Prototypes

void update();
void init();

void draw();

void drawImage(int x, int y, SDL_Surface* src, SDL_Surface* dest);
void drawGrid();
void drawPiece();

void nextPiece();
void rotatePiece(bool clockwise = true);

void moveX(int dir);
void moveY();

void projectPiece();

bool collisionDetected();

// Variables (SDL)

SDL_Event event;

SDL_Surface *screen;

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

SDL_Surface *LoadSurfaceFromFile(std::string filename);

// Main

using namespace std;

int main(int argc, char* args[])
{
	screen = SDL_SetVideoMode(600, 600, 32, SDL_SWSURFACE);

	init();

	nextPiece();

	while (true)
	{
		update();

		while (SDL_PollEvent(&event))
		{
			// Handle keyboard events
			if (event.type == SDL_KEYDOWN)
			{
				switch (event.key.keysym.sym)
				{
				case SDLK_ESCAPE: // "Escape" pressed
					return 0;
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
			// "X" clicked
			else if (event.type == SDL_QUIT)
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

	// Load pieces
	SQUARE_BLUE = LoadSurfaceFromFile("img/blue.png");
	SQUARE_RED = LoadSurfaceFromFile("img/red.png");
	SQUARE_GREEN = LoadSurfaceFromFile("img/green.png");
	SQUARE_YELLOW = LoadSurfaceFromFile("img/yellow.png");
	SQUARE_CYAN = LoadSurfaceFromFile("img/cyan.png");
	SQUARE_PURPLE = LoadSurfaceFromFile("img/purple.png");
	SQUARE_ORANGE = LoadSurfaceFromFile("img/orange.png");

	// Set border
	borderInner.x = 200;
	borderInner.y = 100;
	borderInner.h = 400;
	borderInner.w = 200;

	borderOuter.x = borderInner.x - 10;
	borderOuter.y = borderInner.y - 10;
	borderOuter.h = borderInner.h + 10 * 2;
	borderOuter.w = borderInner.w + 10 * 2;

	// Reset arrays
	memset(grid, 0, sizeof(grid[0][0]) * 200);

	//// Fill grad with random data
	//for (int y = 0; y < 20; y++)
	//{
	//	for (int x = 0; x < 10; x++)
	//	{
	//		grid[y][x] = rand() % 7 + 1;
	//	}
	//}
}

void nextPiece()
{
	memset(piece, 0, sizeof(piece[0][0]) * 16);

	int color = rand() % 7 + 1;

	pieceX = 0;
	pieceY = 0;

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
		nextPiece();
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

// Handle gravity/graphics/movement
void update()
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

	// Refresh the screen
	SDL_Flip(screen);
}

// graphics "master function"
void draw()
{
	// Clear everything
	SDL_FillRect(screen, NULL, 0);

	// Draw grid border
	SDL_FillRect(screen, &borderOuter, SDL_MapRGB(screen->format, 0, 225, 255));
	SDL_FillRect(screen, &borderInner, 0);

	// Draw blocks in the grid
	drawGrid();

	// Draw the piece
	drawPiece();
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
				drawImage(x * 20 + borderInner.x, y * 20 + borderInner.y, SQUARE_CURRENT, screen);
		}
	}
}

void drawPiece()
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
				drawImage((x + pieceX) * 20 + borderInner.x, (y + pieceY) * 20 + borderInner.y, SQUARE_CURRENT, screen);
		}
	}
}

SDL_Surface *LoadSurfaceFromFile(string filename)
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