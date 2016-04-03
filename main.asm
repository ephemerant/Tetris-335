.586
.model flat, C
.stack

init PROTO C
gameLoop PROTO C
TTF_Quit PROTO C
SDL_Quit PROTO C

.data

.code

_MainCallback PROC
	call init
	call gameLoop
	call TTF_Quit
	call SDL_Quit
	ret
_MainCallback ENDP

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