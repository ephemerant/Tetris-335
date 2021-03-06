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
#include "SDL/SDL_ttf.h"

// Variables
const int framesPerFall = 15;
const int framesPerSecond = 60;

int frames = 0;

int score;

int grid[20][10];

int piece[4][4];
int nextPiece[4][4];

int pieceX;
int pieceY;
int color;

bool rightDown = false;
bool leftDown = false;
bool downDown = false;

bool titleScreen = true;
bool gameOver = false;

int rightDownTime = 0;
int leftDownTime = 0;

// Prototypes

void draw();
void drawImage(int x, int y, SDL_Surface* src, SDL_Surface* dest);
void drawGrid();
void drawGridLines();
void drawText();
void drawPiece(int(&piece)[4][4], int pieceX, int pieceY);

void clearRows();

// Variables (SDL)
SDL_Event event;

SDL_Surface *SCREEN;

SDL_Surface *TITLE_SCREEN;
SDL_Surface *GAME_OVER;
SDL_Surface *SCORE;
SDL_Surface *LABEL_SCORE;


SDL_Surface *SQUARE_BLUE;
SDL_Surface *SQUARE_CYAN;
SDL_Surface *SQUARE_RED;
SDL_Surface *SQUARE_YELLOW;
SDL_Surface *SQUARE_ORANGE;
SDL_Surface *SQUARE_PURPLE;
SDL_Surface *SQUARE_GREEN;

SDL_Rect borderOuter;
SDL_Rect borderInner;
SDL_Rect square;
SDL_Rect textBox;
SDL_Rect textBoxScore;

Mix_Music *AUDIO_MAIN;
Mix_Chunk *AUDIO_LINE;

TTF_Font *FONT_UBUNTU_MONO_BOLD;

SDL_Color COLOR_WHITE = { 255, 255, 255 };

// Protypes (SDL)
SDL_Surface *LoadImage(std::string filename);

extern "C"
{
	// Import
	void _MainCallback();
	int _RotatePiece(int(&piece)[4][4], int(&grid)[20][10], int pieceX, int pieceY);
	void _BeginGame(int(&piece)[4][4], int color, int(&grid)[20][10], int(&pieceX), int(&pieceY), int(&nextPiece)[4][4],
		int(&score), bool(&downDown), bool(&rightDown), bool(&leftDown), int(&rightDownTime), int(&leftDownTime));
	int _LoadPieceType(int(&piece)[4][4], int color);
	int _ClearRows(int(&grid)[20][10]);
	bool _CollisionDetected(int(&piece)[4][4], int(*grid)[20][10], int pieceX, int pieceY);
	void _ProjectPiece(int(*piece)[4][4], int(*grid)[20][10], int pieceX, int pieceY);
	void _CopyPiece(int(*A)[4][4], int(*B)[4][4]);
	int _RotateClockwise(int(*A)[4][4], int(*B)[4][4]);
	void _ShiftUp(int(*A)[4][4]);
	void _ClearArray(int(&piece)[20][10], int len);
	void _moveX(int direction, int(&piece)[4][4], int(&grid)[20][10], int(&pieceX), int(&pieceY));
	void _moveY(int(&piece)[4][4], int(&grid)[20][10], int(&pieceX), int(&pieceY), bool(&gameOver), int(&nextPiece)[4][4],
		int color, int(&score));
	
	// Export
	void init();
	void update();
	bool gameTick();
	bool handleInput();
	void TTF_Quit();
	void SDL_Quit();
	unsigned int SDL_GetTicks();
	void soundFX();
}

// Main
using namespace std;

int __stdcall WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
	// Pass the baton to the Assembly code
	_MainCallback();
	return 0;
}

bool handleInput() {
	while (SDL_PollEvent(&event)) {
		if (event.type == SDL_QUIT) // "X" clicked
			return false;
		else if (titleScreen || gameOver) { // Out-of-game keyboard events
			if (event.type == SDL_KEYDOWN) {
				switch (event.key.keysym.sym) {
				case SDLK_RETURN: // "ENTER" pressed
					titleScreen = false;
					gameOver = false;
					_BeginGame(piece, rand() % 7 + 1, grid, pieceX, pieceY, nextPiece, score, downDown, rightDown, leftDown, rightDownTime, leftDownTime);
					break;
				}
			}
		}
		else { // In-game keyboard events
			if (event.type == SDL_KEYDOWN) {
				switch (event.key.keysym.sym) {
				case SDLK_UP: // "UP" pressed
					_RotatePiece(piece, grid, pieceX, pieceY);
					break;
				case SDLK_RIGHT: // "RIGHT" pressed
					rightDown = true;
					break;
				case SDLK_LEFT: // "LEFT" pressed
					leftDown = true;
					break;
				case SDLK_DOWN: // "DOWN" pressed
					downDown = true;
					break;
				}
			}
			else if (event.type == SDL_KEYUP) {
				switch (event.key.keysym.sym) {
				case SDLK_RIGHT: // "RIGHT" released
					rightDown = false;
					rightDownTime = 0;
					break;
				case SDLK_LEFT: // "LEFT" released
					leftDown = false;
					leftDownTime = 0;
					break;
				case SDLK_DOWN: // "DOWN" released
					downDown = false;
					break;
				}
			}
		}
	}
	return true;
}

void init() {
	SDL_Init(SDL_INIT_EVERYTHING);
	TTF_Init();

	SCREEN = SDL_SetVideoMode(600, 600, 32, SDL_SWSURFACE);

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

	// Load audio
	Mix_OpenAudio(11025, MIX_DEFAULT_FORMAT, 2, 1024);

	AUDIO_MAIN = Mix_LoadMUS("audio/main_theme.wav");

	AUDIO_LINE = Mix_LoadWAV("audio/line_clear.wav");

	// Start Music
	Mix_PlayMusic(AUDIO_MAIN, -1);

	// Set border
	borderInner.x = 200;
	borderInner.y = 100;
	borderInner.h = 400;
	borderInner.w = 200;

	borderOuter.x = borderInner.x - 5;
	borderOuter.y = borderInner.y - 5;
	borderOuter.h = borderInner.h + 5 * 2;
	borderOuter.w = borderInner.w + 5 * 2;

	// Load font
	FONT_UBUNTU_MONO_BOLD = TTF_OpenFont("font/UbuntuMono-Bold.ttf", 24);
	LABEL_SCORE = TTF_RenderText_Solid(FONT_UBUNTU_MONO_BOLD, "Score:", COLOR_WHITE);

	textBox.x = borderOuter.x + borderOuter.w + 20;
	textBox.y = borderOuter.y + borderOuter.h - 40;

	textBoxScore.x = textBox.x + 80;
	textBoxScore.y = textBox.y;

	_BeginGame(piece, rand() % 7 + 1, grid, pieceX, pieceY, nextPiece, score, downDown, rightDown, leftDown, rightDownTime, leftDownTime);
}

void soundFX() { Mix_PlayChannel(-1, AUDIO_LINE, 0); }

// Handle gravity/graphics/movement
void update() {
	// Clear everything
	SDL_FillRect(SCREEN, NULL, 0);

	if (titleScreen)
		drawImage(50, 50, TITLE_SCREEN, SCREEN);
	else if (gameOver)
		drawImage(50, 50, GAME_OVER, SCREEN);
	else {
		if (rightDown && !leftDown && !(rightDownTime++ % 6)) // Move right every 6 frames if right is held
			_moveX(1, piece, grid, pieceX, pieceY);
		else if (!rightDown && leftDown && !(leftDownTime++ % 6))
			_moveX(-1, piece, grid, pieceX, pieceY);

		if (downDown)
			frames += 8;
		if (++frames > framesPerFall) {
			_moveY(piece, grid, pieceX, pieceY, gameOver, nextPiece, rand() % 7 + 1, score);
			frames = 0;
		}
		draw();
	}

	// Refresh the screen
	SDL_Flip(SCREEN);
}

// graphics "master function"
void draw() {
	// Draw grid border
	SDL_FillRect(SCREEN, &borderOuter, SDL_MapRGB(SCREEN->format, 0, 170, 220));
	SDL_FillRect(SCREEN, &borderInner, SDL_MapRGB(SCREEN->format, 0, 75, 100));

	drawGridLines();

	// Draw blocks in the grid
	drawGrid();

	// Draw the pieces
	drawPiece(piece, pieceX, pieceY);
	drawPiece(nextPiece, 12, 0);

	// Draw on-screen text
	drawText();
}

void drawText()
{
	// Draw the text "Score:", as well as the actual score

	SCORE = TTF_RenderText_Solid(FONT_UBUNTU_MONO_BOLD, to_string(score).c_str(), COLOR_WHITE);

	SDL_BlitSurface(SCORE, NULL, SCREEN, &textBoxScore);
	SDL_BlitSurface(LABEL_SCORE, NULL, SCREEN, &textBox);

	SDL_FreeSurface(SCORE); // Dispose of SCORE, otherwise we'll have a memory leak
}

void drawGridLines()
{
	// Draw the 20*10 gridlines for the playing area

	for (int y = 0; y < 20; y++) {
		for (int x = 0; x < 10; x++) {
			square.w = 19;
			square.h = 19;

			square.x = x * 20 + borderInner.x;
			square.y = y * 20 + borderInner.y;

			SDL_FillRect(SCREEN, &square, SDL_MapRGB(SCREEN->format, 0, 10, 30));
		}
	}
}

void drawImage(int x, int y, SDL_Surface* src, SDL_Surface* dest) {
	// Draw the image "src" to "dest" with offset (x, y)

	SDL_Rect offset;

	offset.x = x;
	offset.y = y;

	SDL_BlitSurface(src, NULL, dest, &offset);
}

void drawGrid() {
	// Display the pieces that have been dropped into the grid

	for (int y = 0; y < 20; y++) {
		for (int x = 0; x < 10; x++) {
			SDL_Surface *SQUARE_CURRENT = NULL;

			switch (grid[y][x])
			{
			case 1: SQUARE_CURRENT = SQUARE_BLUE; break;
			case 2: SQUARE_CURRENT = SQUARE_RED; break;
			case 3: SQUARE_CURRENT = SQUARE_GREEN; break;
			case 4: SQUARE_CURRENT = SQUARE_CYAN; break;
			case 5: SQUARE_CURRENT = SQUARE_PURPLE; break;
			case 6: SQUARE_CURRENT = SQUARE_YELLOW; break;
			case 7: SQUARE_CURRENT = SQUARE_ORANGE; break;
			}

			if (SQUARE_CURRENT != NULL) // If grid[y][x] was non-zero, display the corresponding square
				drawImage(x * 20 + borderInner.x, y * 20 + borderInner.y, SQUARE_CURRENT, SCREEN);
		}
	}
}

void drawPiece(int(&piece)[4][4], int pieceX, int pieceY) {
	// Draw the current piece based on its position within the grid

	for (int y = 0; y < 4; y++) {
		for (int x = 0; x < 4; x++) {
			SDL_Surface *SQUARE_CURRENT = NULL;

			switch (piece[y][x]) {
			case 1: SQUARE_CURRENT = SQUARE_BLUE; break;
			case 2: SQUARE_CURRENT = SQUARE_RED; break;
			case 3: SQUARE_CURRENT = SQUARE_GREEN; break;
			case 4: SQUARE_CURRENT = SQUARE_CYAN; break;
			case 5: SQUARE_CURRENT = SQUARE_PURPLE; break;
			case 6: SQUARE_CURRENT = SQUARE_YELLOW; break;
			case 7: SQUARE_CURRENT = SQUARE_ORANGE; break;
			}

			if (SQUARE_CURRENT != NULL) // Only draw non-empty squares
				drawImage((x + pieceX) * 20 + borderInner.x, (y + pieceY) * 20 + borderInner.y, SQUARE_CURRENT, SCREEN);
		}
	}
}

SDL_Surface *LoadImage(string filename) {
	// Load and return the image found at "filename"

	SDL_Surface* LoadedImage = NULL;
	SDL_Surface* OptimizedImage = NULL;

	LoadedImage = IMG_Load(filename.c_str());

	if (LoadedImage != NULL) {
		OptimizedImage = SDL_DisplayFormat(LoadedImage);
		SDL_FreeSurface(LoadedImage);
	}

	return OptimizedImage;
}