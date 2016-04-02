.386
.model flat, C

init PROTO C
gameLoop PROTO C
TTF_Quit PROTO C
SDL_Quit PROTO C

.data

.code

MainCallback PROC
	call init
	call gameLoop
	call TTF_Quit
	call SDL_Quit
	ret
MainCallback ENDP

END