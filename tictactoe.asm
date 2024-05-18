section .data
	DRAWMSG:	db 'Draw', 10
	DRAWLEN:	equ $-DRAWMSG
	WINMSG:		db ' won!', 10
	WINLEN:		equ $-WINMSG
	MVERRMSG:	db 'Invalid Move',10
	MVERRLEN:	equ $-MVERRMSG
	X_SYM:		db 'x'
	Y_SYM:		db 'o'
	BOARD:		db '0|1|2',10,'3|4|5',10,'6|7|8',10
	BOARDLEN:	equ $-BOARD

section .bss
	RBUFF		resq 1
section .text

global _start

_start:
game:
	; Print board state
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, BOARD
	mov	rdx, BOARDLEN
	syscall
	; Read move
move:
	mov	rax, 0
	mov	rdi, 1
	mov	rsi, RBUFF
	mov	rdx, 8
	syscall
	mov	al, byte [RBUFF]
	sub	rax, 48
	cmp	rax, 0
	jl	mverr
	cmp	rax, 10
	jge	mverr
	; Move is a valid number
	; Now check if the space is taken
	mov	r12, rax
	mov	rax, 2
	mul	r12
	mov	r12, rax
check:
	add	r12, BOARD
	mov	al, byte [r12]
	cmp	rax, 56		; If space on board is larger than ascii for num then it's taken already
	jg	mverr
	mov	rax, r10
	shl	rax, 7
	cmp	al, 0
	je	x_place
	jne	y_place
x_place:
	mov	al, [X_SYM]	; Moves ASCII for x to lower byte of rax
	mov	[r12], al	; Stores that value in the mem address of the square as stored in r12
	jmp	new_turn
y_place:
	mov	al, [Y_SYM]
	mov	[r12], al
	jmp	new_turn

new_turn:
	inc	r10		; Increments turn counter
	cmp	r10, 9		; 9 turns is max, only 9 squares duh
	jge	draw		; Print draw message and quit
	cmp	r10, 5		; Can't win before turn 5 so it's a waste to check
	jl	game
	; Check for a win
	mov	rax, BOARD	; I don't remeber why I did this
	mov	r15, BOARD	; Or this, or the next one
	add	r15, BOARDLEN
win_check:
	; This one is a doozy
	xor	r14, r14
	xor	r11, r11
	shl	r10, 7		; Gets the last bit of the turn counter as the sole bit in the lower byte of r10
	cmp	r10b, 0		; If that bit is set r10b will be 128, otherwise it will be zero
	jne	x_check		; This effectivly checks if it is even or odd, if odd then the turn that just placed is x
	jmp	y_check		; because I increment the counter up there

x_check:
	; This whole thing is wack
	; Because three in a row must cross the board a win condition will always have one of the 5 edge spaces filled
	; So we only need to check from those
	; These are the 0, 1, 2, 3, and 6 spots
	; First the focal spot is checked, if it isn't the right type then we skip to the next
	; Otherwise we add up the values of all the possible win states that come from that spot
	; And if that equals 360 for x or 333 for o/y it is a BIG WIN!!!!!!
	; It would actually be faster to check each space rather than add them because I have to 
	; Fetch from memory into the low byte of the register before adding rather than fetching directly to add
	; Because that would add 8 bytes which sucks, and if I did add r11b, [BOARD] when it broke 255 it would get the wrong value
	; I guess I could have figured out the right number.
	; In hindsight that would have been way easier than changing a million 'add r14, []' to 'mov r14b, [] add r11, r14'
	; Dammit
	shr	r10, 7
	mov	r11b, [BOARD]
	cmp	r11, 120
	jne	x_ctwo
	; Checks from square one
	mov	r14b, [BOARD+2]
	add	r11, r14
	mov	r14b, [BOARD+4]
	add	r11, r14
	cmp	r11, 360
	je	x_win
	mov	r11, 120
	mov	r14b, [BOARD+6]
	add	r11, r14
	mov	r14b, [BOARD+12]
	add	r11, r14
	cmp	r11, 360
	je	x_win
	mov	r11, 120
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+16]
	add	r11, r14
	cmp	r11, 360
	je	x_win
	
x_ctwo:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+2]
	cmp	r11, 120
	jne	x_cthree
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+14]
	add	r11, r14
	cmp	r11, 360
	je	x_win
x_cthree:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+4]
	cmp	r11, 120
	jne	x_cfour
	mov	r14b, [BOARD+10]
	add	r11, r14
	mov	r14b, [BOARD+16]
	add	r11, r14
	cmp	r11, 360
	je	x_win
	mov	r11, 120
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+12]
	add	r11, r14
	cmp	r11, 360
	je	x_win
x_cfour:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+6]
	cmp	r11, 120
	jne	x_cfive
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+10]
	add	r11, r14
	cmp	r11, 360
	je	x_win
x_cfive:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+12]
	cmp	r11, 120
	jne	game
	mov	r14b, [BOARD+14]
	add	r11, r14
	mov	r14b, [BOARD+16]
	add	r11, r14
	cmp	r11, 360
	jne	game
x_win:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, X_SYM
	mov	rdx, 1
	syscall
	jmp	win
y_check:
	shr	r10, 7
	mov	r11b, [BOARD]
	cmp	r11, 111
	jne	y_ctwo
	; Checks from square one
	mov	r14b, [BOARD+2]
	add	r11, r14
	mov	r14b, [BOARD+4]
	add	r11, r14
	cmp	r11, 333
	je	y_win
	mov	r11, 111
	mov	r14b, [BOARD+6]
	add	r11, r14
	mov	r14b, [BOARD+12]
	add	r11, r14
	cmp	r11, 333
	je	y_win
	mov	r11, 111
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+16]
	add	r11, r14
	cmp	r11, 333
	je	y_win
	
y_ctwo:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+2]
	cmp	r11, 111
	jne	y_cthree
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+14]
	add	r11, r14
	cmp	r11, 333
	je	y_win
y_cthree:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+4]
	cmp	r11, 111
	jne	y_cfour
	mov	r14b, [BOARD+10]
	add	r11, r14
	mov	r14b, [BOARD+16]
	add	r11, r14
	cmp	r11, 333
	je	y_win
	mov	r11, 111
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+12]
	add	r11, r14
	cmp	r11, 333
	je	y_win
y_cfour:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+6]
	cmp	r11, 111
	jne	y_cfive
	mov	r14b, [BOARD+8]
	add	r11, r14
	mov	r14b, [BOARD+10]
	add	r11, r14
	cmp	r11, 333
	je	y_win
y_cfive:
	xor	r11, r11
	xor	r14, r14
	mov	r11b, [BOARD+12]
	cmp	r11, 111
	jne	game
	mov	r14b, [BOARD+14]
	add	r11, r14
	mov	r14b, [BOARD+16]
	add	r11, r14
	cmp	r11, 333
	jmp	game
y_win:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, Y_SYM
	mov	rdx, 1
	syscall
	jmp win
draw:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, DRAWMSG
	mov	rdx, DRAWLEN
	syscall
	call	end
win:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, WINMSG
	mov	rdx, WINLEN
	syscall
	call	end

mverr:
	; Prints move error message
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, MVERRMSG
	mov	rdx, MVERRLEN
	syscall

	jmp	move	; Re-read move
global end
end:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, BOARD
	mov	rdx, BOARDLEN
	syscall
global exit
exit:
	mov	rax, 60
	mov	rdi, 0
	syscall
