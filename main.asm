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

; Clear any full rows, and return the number cleared
_ClearRows PROC
	push ebp
	mov ebp, esp

	mov esi, 0			; # of clears
	mov edi, [ebp+8]	; &grid[20][10]

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
				mov eax, ebx
				mov edx, 10
				mul edx
				add eax, ecx
				mov edx, 4
				mul edx
				add eax, edi
				mov eax, [eax]
				cmp eax, 0 ; &grid[y][x] == 0 ?
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
					mov [eax], edx

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

	pop ebp
	ret
_ClearRows ENDP

; Load the expected piece configuration into &piece
_LoadPieceType PROC
	push ebp	
	mov ebp, esp

	mov eax, [ebp+8]	; int &piece[4][4]
	mov ebx, [ebp+12]	; int color

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

	pop ebp
	ret
_LoadPieceType ENDP

END