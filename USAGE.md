## Creating the Project
1. Create an Empty C++ Project
1. Drag main.cpp from your GitHub directory into "Source files" in Visual Studio
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_4.png)
1. Run compile.bat from your GitHub directory, which will create/update main.obj with the latest compiled version of main.asm
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_5.png)
1. Drag main.obj into "Source files"
1. Open main.cpp and main.asm
1. I have my windows positioned to quickly work on both
1. I use [AsmHighlighter](https://visualstudiogallery.msdn.microsoft.com/6b069ed9-963a-430d-be66-7dace0f1f1c2) to highlight my ASM code
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_7.png)

## Project Configuration
1. Click Project->Properties
1. Go to Linker, and enter the path for the GitHub directoriy's "lib/x86" path into "Additional Library Lirectories"
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_9.png)
1. Go to Linker->Input and enter the following for "Additional Dependencies" (click the dropdown arrow to the right and click Edit, and then enter them in the top section, one per line):
    * legacy_stdio_definitions.lib
    * SDL.lib
    * SDLmain.lib
    * SDL_image.lib
    * SDL_mixer.lib
    * SDL_ttf.lib
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_10.png)
1. Go to Linker->System, and under SubSystem, select "Windows"
1. Build the project, and there *should* be no errors

## Moving Files
1. To be able to run the project through VS, we'll need to move a few files into specific locations
1. You should now have two directories: the GitHub one (with the code) and the VS one (with the project settings and .exe)
1. To get to your VS one, right click your project and select "Open Folder in File Explorer"
1. In the folder that opens, paste the **audio**, **font**, and **img** folders from the GitHub directory
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_11.png)
1. Go up one directory (note the two "Tetris 335"s) and then go to Debug
1. Here, you want to paste the **dlls** from the GitHub directory
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_12.png)
1. You should now be able to press Ctrl+F5 in VS and build and run the game
    * ![](https://raw.githubusercontent.com/ephemerant/Tetris-335/master/img/tutorial/Screenshot_13.png)
