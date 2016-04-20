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
soundFX PROTO C

.data

TempPiece dd 16 dup(0) ; A 4x4 grid for temporary piece operations

.code

_MainCallback PROC
	call init ; Initialize SDL, load resources, begin game
	call _GameLoop ; Apply gravity, handle keyboard input, etc, until the player loses
	call TTF_Quit ; Unload fonts
	call SDL_Quit ; Unload other resources
	ret
_MainCallback ENDP

_GameLoop PROC
	@@WHILE:
		call _GameTick ; Called once per frame
		cmp eax, 0
		jne @@WHILE
	@@ENDWHILE:
	ret
_GameLoop ENDP

_GameTick PROC
	call SDL_GetTicks
	push eax

	call update ; Apply gravity, handle movement, draw graphics

	call handleInput ; Handle keyboard commands, etc
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
	xor esi, esi ; Temporary constant of 0 for mov [eax], esi
	xor ecx, ecx
	@@WHILE:
		cmp ecx, len
		jb @@DO
		jmp @@ENDWHILE
	@@DO:
		mov eax, ecx		
		mul ebx
		add eax, piece

		mov [eax], esi ; Overwrite current index with 0

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
		xor ecx, ecx		; x
		@@FORX:
			cmp ecx, 4
			jb @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov eax, ebx ; Calculate the adjusted index based on x and y-1
			dec eax
			mov edx, 4
			mul edx

			add eax, ecx
			mov edx, 4
			mul edx ; We have now calculated the adjusted index

			add eax, A	; Get the address of the calculated position

			invoke _GetValueAt, A, ecx, ebx, 4 ; Set edx to A[y][x]
			mov [eax], edx	; A[y-1][x] = A[y][x];

			add eax, 16
			xor edx, edx
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
	xor esi, esi			; bit flags representing empty rows

	xor ebx, ebx			; y
	@@FORY:
		cmp ebx, 4
		jb @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		xor ecx, ecx		; x
		@@FORX:
			cmp ecx, 4
			jb @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov eax, ecx	; Manipulate x and y to access B[x][3-y], i.e. B + 4((4 * x) + (3 - y))
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

			@@IFVALUE: ; Store within esi information about the rows			
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

				; Bit values of esi:
				;	1 = First row non-empty
				;	2 = Second row non-empty
				;	4 = Fourth row non-empty
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

; Copy piece A into B
_CopyPiece PROC, A:PTR DWORD, B:PTR DWORD
	xor ebx, ebx			; y
	@@FORY:
		cmp ebx, 4
		jb @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		xor ecx, ecx		; x
		@@FORX:
			cmp ecx, 4
			jb @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov eax, ebx ; We want to access B[y][x], i.e. B + 4(4*y + x)
			mov edx, 4
			mul edx

			add eax, ecx
			mov edx, 4
			mul edx

			add eax, B	; Get the address of the calculated position

			invoke _GetValueAt, A, ecx, ebx, 4 ; Set edx = A[y][x]
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
	xor ebx, ebx			; y
	@@FORY:
		cmp ebx, 4
		jl @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		xor ecx, ecx		; x
		@@FORX:
			cmp ecx, 4
			jl @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			mov edi, ecx
			add edi, pieceX	; x + pieceX

			mov eax, ebx
			add eax, pieceY	; y + pieceY

			invoke _GetValueAt, grid, edi, eax, 10 ; edx = grid[y + pieceY][x + pieceX]

			cmp edx, 0		; Overwrite blank grid squares only
			jz @@BLANK
			jmp @@NOTBLANK			

			@@BLANK:
				mov edx, 10		; We want eax to correspond to the index for grid[y][x]
								; i.e. eax = grid + 4(10*(y + pieceY) + (x + pieceX))
				mul edx

				add eax, edi
				mov edx, 4
				mul edx

				add eax, grid	; Get the address of the calculated position

				invoke _GetValueAt, piece, ecx, ebx, 4 ; edx = piece[y][x]
				mov [eax], edx	; Copy the piece's square into its calculated position in the grid
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
	xor eax, eax			; default = false (no collision)

	xor ebx, ebx			; y
	@@FORY:
		cmp ebx, 4
		jl @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		xor ecx, ecx		; x
		@@FORX:
			cmp ecx, 4
			jl @@LOOPX
			jmp @@ENDFORX
		@@LOOPX:
			invoke _GetValueAt, piece, ecx, ebx, 4

			cmp edx, 0		; !piece[y][x]
			jz @@NOCOLLISION

			mov edx, ecx
			add edx, pieceX	; edx = x + pieceX

			mov esi, ebx
			add esi, pieceY	; esi = y + pieceY

			cmp edx, 9		; too far right
			jg @@COLLISION
			cmp edx, 0		; too far left
			jl @@COLLISION

			cmp esi, 19		; too far down
			jg @@COLLISION
			cmp esi, 0		; too far up
			jl @@COLLISION
			
			invoke _GetValueAt, grid, edx, esi, 10 ; edx = grid[y + pieceY][x + pieceX]

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

; Clear any full rows, and return the number cleared
_ClearRows PROC, grid:PTR DWORD, score:PTR DWORD
	xor esi, esi		; # of clears
	mov edi, grid

	mov ebx, 19			; y
	@@FORY:
		cmp ebx, 0
		jge @@LOOPY
		jmp @@ENDFORY
	@@LOOPY:
		xor ecx, ecx	; x
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
				xor ecx, ecx ; Mark as empty
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
				xor edx, edx
				@@FORX2:
					cmp edx, 10
					jb @@LOOPX2
					jmp @@ENDFORX2
				@@LOOPX2:
					push edx
					mov edx, 10 ; We want eax to refer to the index that corresponds to grid[y][x]
								; i.e. grid + 4(10*y + x)
					mov eax, ecx
					mul edx
					pop edx

					push edx
					add eax, edx
					mov edx, 4
					mul edx
					add eax, edi					

					mov edx, [eax-40]	; edx = grid[y-1][x]
					mov [eax], edx		; Move to the square the contents of the square above it

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

		cmp esi, 0
		jz @@NOWIN		; skip the fun
		
		mov ebx, score
		mov ecx, [ebx]
		mov eax, 10
		mul esi
		add ecx, eax
		mov [ebx], ecx		; add to score
		call soundFX		; play the sounds if cleared

	@@NOWIN:
		mov eax, esi
	ret
_ClearRows ENDP

; Load the expected piece configuration into &piece
_LoadPieceType PROC, piece:PTR DWORD, color:DWORD
	invoke _ClearArray, piece, 16 ; Clear piece out, so we can have a fresh slate to write to

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
		; Load the various piece structures
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

_loadNextPiece PROC, x:PTR DWORD, y:PTR DWORD, nextPiece:PTR DWORD, piece:PTR DWORD, color:DWORD
	push eax
	push ebx

	mov ebx, 2
	mov eax, x
	mov [eax], ebx ; pieceX = 2

	mov ebx, -1
	mov eax, y
	mov [eax], ebx ; pieceY = -1

	invoke _CopyPiece, nextPiece, piece ; Copy nextPiece into piece
	invoke _LoadPieceType, nextPiece, color ; Load a new piece of type color into nextPiece

	pop ebx
	pop eax
	ret
_loadNextPiece ENDP

_moveX PROC, direction:DWORD, piece:PTR DWORD, grid:PTR DWORD, pieceX:PTR DWORD ,pieceY:PTR DWORD
	push eax
	push ebx
	push edx
	push ecx

	mov edx, pieceX		
	mov ebx, [edx]			; x = pieceX
	add ebx, direction		; x = pieceX + direction
	mov [edx], ebx			; Effectively, pieceX += direction
	mov ecx, pieceY
	mov eax, [ecx]

	invoke _CollisionDetected, piece, grid, ebx, eax ; See if moving the piece results in a collision

	cmp eax, 0				; When eax = 0, no collision
	jz @@MoveXcomplete

	; If collision, restore pieceX
	mov edx, pieceX		
	mov ebx, [edx]			; x = pieceX
	sub ebx, direction		; x = pieceX - direction
	mov [edx], ebx			; pieceX -= direction

	@@MoveXcomplete:
		pop ecx
		pop edx
		pop ebx
		pop eax
		ret
_moveX ENDP

_moveY PROC, piece:PTR DWORD, grid:PTR DWORD, pieceX:PTR DWORD, pieceY:PTR DWORD, gameOver:PTR DWORD,
		   nextPiece:PTR DWORD, color:DWORD, score:PTR DWORD
	push eax
	push ebx
	push edx
	push ecx

	mov edx, pieceY		
	mov ebx, [edx]
	inc ebx
	mov [edx], ebx	; Increment pieceY (move the piece down)
	mov ebx, pieceX

	mov ecx, piece
	mov eax, [ecx]

	invoke _CollisionDetected, piece, grid, [ebx], [edx]

	cmp eax, 0			; Is there a collision after moving the piece down?
	jz @@MoveYcomplete	; 0 = No collision

	; Collision detected, so place the piece
	mov edx, pieceY		
	mov ebx, [edx]
	dec ebx
	mov [edx], ebx		; Decrement pieceY (restore it to pre-collision value)
	mov ebx, pieceX
	
	invoke _ProjectPiece, piece, grid, [ebx], [edx] ; Place the piece

	invoke _ClearRows, grid, score ; Clear any rows that the piece just filled

	invoke _loadNextPiece, pieceX, pieceY, nextPiece, piece, color ; Load the next piece

	mov ebx, piece
	mov ecx, [ebx]
	mov ebx, pieceX
	mov eax, [ebx]
	mov ebx, pieceY
	mov edx, [ebx]

	invoke _CollisionDetected, piece, grid, eax, edx	; Check if the new piece immediately collides
														; If so, game over!

	cmp eax, 0
	jz @@MoveYcomplete

	mov eax, 1
	mov ebx, gameOver
	mov [ebx], eax

	@@MoveYcomplete:
		pop ecx
		pop edx
		pop ebx
		pop eax
		ret
_moveY ENDP

_BeginGame PROC, piece:PTR DWORD, color:DWORD, grid:PTR DWORD, x:PTR DWORD, y:PTR DWORD, nextPiece:PTR DWORD,
			  score:PTR DWORD, downDown:PTR DWORD, rightDown:PTR DWORD, leftDown:PTR DWORD, rightDownTime:PTR DWORD,
			  leftDownTime:PTR DWORD
	push eax
	push ebx

	xor ebx, ebx
	mov eax, score
	mov [eax], ebx ; Set score = 0

	mov eax, downDown
	mov [eax], ebx ; Set downDown = 0

	mov eax, rightDown
	mov [eax], ebx ; Set rightDown = 0

	mov eax, leftDown
	mov [eax], ebx ; set leftDown = 0

	mov eax, rightDownTime
	mov [eax], ebx ; Set rightDownTime = 0

	mov eax, leftDownTime
	mov [eax], ebx ; Set leftDownTime = 0

	invoke _LoadPieceType, piece, color ; Load first piece

	invoke _loadNextPiece, x, y, nextPiece, piece, color

	invoke _ClearArray, grid, 200

	pop ebx
	pop eax
	ret
_BeginGame ENDP

END