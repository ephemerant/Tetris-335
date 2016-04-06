.586
.model flat, C
.stack

init PROTO C
gameTick PROTO C
TTF_Quit PROTO C
SDL_Quit PROTO C

SDL_GetTicks PROTO C
update PROTO C
handleInput PROTO C
SDL_Delay PROTO C, ticks:DWORD

.data

TempPiece dd 16 dup(0)

.code

_MainCallback PROC
	call init
	call _GameLoop
	call TTF_Quit
	call SDL_Quit
	ret
_MainCallback ENDP

_GameLoop PROC
	@@WHILE:
		call _GameTick
		cmp eax, 0
		jne @@WHILE
	@@ENDWHILE:
	ret
_GameLoop ENDP

_GameTick PROC
	call SDL_GetTicks
	push eax

	call update

	call handleInput
	push eax

	call SDL_GetTicks
	mov ebx, eax
	
	pop ecx	; "X" clicked? T/F
	pop edx ; old ticks
	
	@@IF:
		sub eax, edx
		cmp eax, 17 ; ~60 fps
		jb @@THEN
		jmp @@ENDIF
	@@THEN:
		neg eax
		add eax, 17
		invoke SDL_Delay, eax	; wait remaining ticks
	@@ENDIF:

	mov eax, ecx ; return the result of the user's input (1 = continue, 0 = end game)
	
	ret
_GameTick ENDP

; Helper method to get the value at grid[y][x]
; edx = return value
_GetValueAt PROC, grid:PTR DWORD, x:DWORD, y:DWORD, w:DWORD
	push eax

	mov eax, y
	mul w			; y *= width
	
	add eax, x		; y += x
	mov edx, 4
	mul edx			; y *= 4

	add eax, grid	; y += grid
					; y = grid + 4(width*y + x)
	mov edx, [eax]

	pop eax
	ret
_GetValueAt ENDP

; Sets the array to contain only 0s
_ClearArray PROC, piece:PTR DWORD, len:DWORD
	mov ebx, 4 ; Byte size of double word
	mov esi, 0 ; Temporary constant of 0 for mov [eax], esi
	mov ecx, 0
	@@WHILE:
		cmp ecx, len
		jb @@DO
		jmp @@ENDWHILE
	@@DO:
		mov eax, ecx		
		mul ebx
		add eax, piece

		mov [eax], esi

		inc ecx
		jmp @@WHILE
	@@ENDWHILE:
	ret
_ClearArray ENDP

; Shift everything in A up by one, discarding the first row
_ShiftUp PROC, A:PTR DWORD
	mov ebx, 1			; y
	@@FORY:
		cmp ebx, 4
		jb @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		mov ecx, 0		; x
		@@FORX:
			cmp ecx, 4
			jb @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov eax, ebx
			sub eax, 1
			mov edx, 4
			mul edx

			add eax, ecx
			mov edx, 4
			mul edx

			add eax, A	; Get the address of the calculated position

			invoke _GetValueAt, A, ecx, ebx, 4
			mov [eax], edx	; A[y-1][x] = A[y][x];

			add eax, 16
			mov edx, 0
			mov [eax], edx	; Clear out the square

			inc ecx
			jmp @@FORX
		@@ENDFORX:

		inc ebx
		jmp @@FORY
	@@ENDFORY:	
	ret
_ShiftUp ENDP

; Rotate A into B
_RotateClockwise PROC, A:PTR DWORD, B:PTR DWORD
	mov esi, 0			; bit flags representing empty rows

	mov ebx, 0			; y
	@@FORY:
		cmp ebx, 4
		jb @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		mov ecx, 0		; x
		@@FORX:
			cmp ecx, 4
			jb @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov eax, ecx
			mov edx, 4
			mul edx

			mov edx, 3
			sub edx, ebx

			add eax, edx
			mov edx, 4
			mul edx

			add eax, B		; End up with B[x][3-y], the rotated position

			invoke _GetValueAt, A, ecx, ebx, 4
			mov [eax], edx	; B[x][3-y] = A[y][x]

			@@IFVALUE:
				cmp edx, 0
				jne @@THENVALUE
				jmp @@ENDIFVALUE
			@@THENVALUE:
				@@SWITCHX:
					cmp ecx, 0
					je @@FIRST
					cmp ecx, 1
					je @@SECOND
					cmp ecx, 3
					je @@LAST
					jmp @@ENDSWITCHx
				@@FIRST:
					or esi, 1
					jmp @@ENDSWITCHx
				@@SECOND:
					or esi, 2
					jmp @@ENDSWITCHx
				@@LAST:
					or esi, 4
				@@ENDSWITCHX:
			@@ENDIFVALUE:

			inc ecx
			jmp @@FORX
		@@ENDFORX:

		inc ebx
		jmp @@FORY
	@@ENDFORY:	
	mov eax, esi
	ret
_RotateClockwise ENDP

; Copy A into B
_CopyPiece PROC, A:PTR DWORD, B:PTR DWORD
	mov ebx, 0			; y
	@@FORY:
		cmp ebx, 4
		jb @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		mov ecx, 0		; x
		@@FORX:
			cmp ecx, 4
			jb @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov eax, ebx
			mov edx, 4
			mul edx

			add eax, ecx
			mov edx, 4
			mul edx

			add eax, B	; Get the address of the calculated position

			invoke _GetValueAt, A, ecx, ebx, 4
			mov [eax], edx	; Copy the square into its calculated position

			inc ecx
			jmp @@FORX
		@@ENDFORX:

		inc ebx
		jmp @@FORY
	@@ENDFORY:	
	ret
_CopyPiece ENDP

; Project the piece onto the grid
_ProjectPiece PROC, piece:PTR DWORD, grid:PTR DWORD, pieceX:DWORD, pieceY:DWORD		
	mov ebx, 0			; y
	@@FORY:
		cmp ebx, 4
		jl @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		mov ecx, 0		; x
		@@FORX:
			cmp ecx, 4
			jl @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov edi, ecx
			add edi, pieceX	; x + pieceX

			mov eax, ebx
			add eax, pieceY	; y + pieceY

			invoke _GetValueAt, grid, edi, eax, 10

			cmp edx, 0		; Overwrite blank squares only
			jz @@BLANK
			jmp @@NOTBLANK			

			@@BLANK:
				mov edx, 10
				mul edx

				add eax, edi
				mov edx, 4
				mul edx

				add eax, grid	; Get the address of the calculated position

				invoke _GetValueAt, piece, ecx, ebx, 4
				mov [eax], edx	; Copy the square into its calculated position
			@@NOTBLANK:

			inc ecx
			jmp @@FORX
		@@ENDFORX:

		inc ebx
		jmp @@FORY
	@@ENDFORY:	
	ret
_ProjectPiece ENDP

; Return true if the piece collides with the grid
_CollisionDetected PROC, piece:PTR DWORD, grid:PTR DWORD, pieceX:DWORD, pieceY:DWORD	
	mov eax, 0			; default = false (no collision)

	mov ebx, 0			; y
	@@FORY:
		cmp ebx, 4
		jl @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		mov ecx, 0		; x
		@@FORX:
			cmp ecx, 4
			jl @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			invoke _GetValueAt, piece, ecx, ebx, 4

			cmp edx, 0		; !piece[y][x]
			jz @@NOCOLLISION

			mov edx, ecx
			add edx, pieceX	; x + pieceX

			mov esi, ebx
			add esi, pieceY	; y + pieceY

			cmp edx, 9		; too far right
			jg @@COLLISION
			cmp edx, 0		; too far left
			jl @@COLLISION

			cmp esi, 19		; too far down
			jg @@COLLISION
			cmp esi, 0		; too far up
			jl @@COLLISION
			
			invoke _GetValueAt, grid, edx, esi, 10

			cmp edx, 0
			jne @@COLLISION

			jmp @@NOCOLLISION

			@@COLLISION:
				mov eax, 1
				jmp @@ENDFORY
			@@NOCOLLISION:

			inc ecx
			jmp @@FORX
		@@ENDFORX:

		inc ebx
		jmp @@FORY
	@@ENDFORY:	
	ret
_CollisionDetected ENDP

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

; Clear any full rows, and return the number cleared
_ClearRows PROC, grid:PTR DWORD
	mov esi, 0			; # of clears
	mov edi, grid

	mov ebx, 19			; y
	@@FORY:
		cmp ebx, 0
		jge @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		mov ecx, 0		; x
		@@FORX:
			cmp ecx, 10
			jb @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			@@IFEMPTY:
				invoke _GetValueAt, grid, ecx, ebx, 10
				cmp edx, 0 ; &grid[y][x] == 0 ?
				je @@THENEMPTY
				jmp @@ENDIFEMPTY
			@@THENEMPTY:
				mov ecx, 0 ; Mark as empty
				jmp @@ENDFORX
			@@ENDIFEMPTY:
			inc ecx
			jmp @@FORX
		@@ENDFORX:

		@@IFFULL:
			cmp ecx, 0
			jne @@THENFULL
			jmp @@ENDIFFULL
		@@THENFULL:
			mov ecx, ebx
			@@FORY2: ; Shift everything down by 1
				cmp ecx, 0
				ja @@LOOPY2
				jmp @@ENDFORY2
			@@LOOPY2:
				mov edx, 0
				@@FORX2:
					cmp edx, 10
					jb @@LOOPX2
					jmp @@ENDFORX2
				@@LOOPX2:
					push edx
					mov edx, 10
					mov eax, ecx
					mul edx
					pop edx

					push edx
					add eax, edx
					mov edx, 4
					mul edx
					add eax, edi					

					mov edx, [eax-40]
					mov [eax], edx ; Move to the square the contents of the square above it

					pop edx

					inc edx
					jmp @@FORX2
				@@ENDFORX2:

				dec ecx
				jmp @@FORY2
			@@ENDFORY2:

			inc ebx
			inc esi
		@@ENDIFFULL:

		dec ebx
		jmp @@FORY
	@@ENDFORY:
	mov eax, esi
	ret
_ClearRows ENDP

; Load the expected piece configuration into &piece
_LoadPieceType PROC, piece:PTR DWORD, color:DWORD
	invoke _ClearArray, piece, 16

	mov eax, piece
	mov ebx, color

	@@SWITCH:
		cmp ebx, 1
		je @@J
		cmp ebx, 2
		je @@Z
		cmp ebx, 3
		je @@S
		cmp ebx, 4
		je @@I
		cmp ebx, 5
		je @@T
		cmp ebx, 6
		je @@O
		cmp ebx, 7
		je @@L
		jmp @@ENDSWITCH
		@@J:
			mov [eax + 16*1 + 4*1], ebx ; y - multiples of 16, x - multiples of 4
			mov [eax + 16*1 + 4*2], ebx
			mov [eax + 16*1 + 4*3], ebx
			mov [eax + 16*2 + 4*3], ebx
			jmp @@ENDSWITCH
		@@Z:
			mov [eax + 16*1 + 4*1], ebx
			mov [eax + 16*1 + 4*2], ebx
			mov [eax + 16*2 + 4*2], ebx
			mov [eax + 16*2 + 4*3], ebx
			jmp @@ENDSWITCH
		@@S:
			mov [eax + 16*1 + 4*2], ebx
			mov [eax + 16*1 + 4*3], ebx
			mov [eax + 16*2 + 4*1], ebx
			mov [eax + 16*2 + 4*2], ebx
			jmp @@ENDSWITCH
		@@I:
			mov [eax + 16*1 + 4*0], ebx
			mov [eax + 16*1 + 4*1], ebx
			mov [eax + 16*1 + 4*2], ebx
			mov [eax + 16*1 + 4*3], ebx
			jmp @@ENDSWITCH
		@@T:
			mov [eax + 16*1 + 4*1], ebx
			mov [eax + 16*1 + 4*2], ebx
			mov [eax + 16*1 + 4*3], ebx
			mov [eax + 16*2 + 4*2], ebx
			jmp @@ENDSWITCH
		@@O:
			mov [eax + 16*1 + 4*1], ebx
			mov [eax + 16*1 + 4*2], ebx
			mov [eax + 16*2 + 4*1], ebx
			mov [eax + 16*2 + 4*2], ebx
			jmp @@ENDSWITCH
		@@L:		
			mov [eax + 16*1 + 4*1], ebx
			mov [eax + 16*1 + 4*2], ebx
			mov [eax + 16*1 + 4*3], ebx
			mov [eax + 16*2 + 4*1], ebx
	@@ENDSWITCH:	
	ret
_LoadPieceType ENDP

END