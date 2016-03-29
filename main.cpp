#include <iostream>
#include <stdio.h>
#include <stdlib.h>

#include <string>
#include <ctype.h>

#include "SDL/SDL.h"
#include "SDL/SDL_image.h"
#include "SDL/SDL_mixer.h"

extern "C" { FILE __iob_func[3] = { *stdin,*stdout,*stderr }; }

// Variables

int ticks = 0;
const int ticksPerFall = 1200;

int grid[20][10] = { 0 };

// Prototypes

void update();
void init();

void drawGUI();
void drawImage(int x, int y, SDL_Surface* src, SDL_Surface* dest);

// Variables (SDL)

SDL_Event event;

SDL_Surface *screen;

SDL_Surface *SPRITE_BLUE;

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

	while (true)
	{
		update();

		if (SDL_PollEvent(&event))
		{
			// Handle keyboard events
			if (event.type == SDL_KEYDOWN)
			{
				switch (event.key.keysym.sym)
				{
				case SDLK_ESCAPE: // "Escape" pressed
					return 0;
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
	SPRITE_BLUE = LoadSurfaceFromFile("../img/blue.png");

	borderOuter.x = 100;
	borderOuter.y = 100;
	borderOuter.h = 400;
	borderOuter.w = 400;

	borderInner.x = borderOuter.x + 20;
	borderInner.y = borderOuter.y + 20;
	borderInner.h = borderOuter.h - 20 * 2;
	borderInner.w = borderOuter.w - 20 * 2;
}

void update()
{
	drawGUI();

	if (++ticks > ticksPerFall)
	{
		ticks = 0;
		cout << "Fall!";
	}

	// Refresh the screen
	SDL_Flip(screen);
}

void drawGUI()
{
	// Clear everything
	SDL_FillRect(screen, NULL, 0);

	// Grid border
	SDL_FillRect(screen, &borderOuter, SDL_MapRGB(screen->format, 0, 200, 255));
	SDL_FillRect(screen, &borderInner, 0);

	// Grid
	drawImage(300, 300, SPRITE_BLUE, screen);
}

void drawImage(int x, int y, SDL_Surface* src, SDL_Surface* dest)
{
	SDL_Rect offset;
	offset.x = x;
	offset.y = y;

	SDL_BlitSurface(src, NULL, dest, &offset);
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