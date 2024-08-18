; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ex4.asm
; 09/06/2022
; Maya Naor 315176362
; Adina Hessen 336165139
; Description: 
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.model small
.stack 100h
.data
	PlayerLocation dw 0
	PointLocation dw 0
	score db 0
	msg_score db 'score: __ $'
	counter db 0
.code
MAIN:
	
	
	;setting the DS
	mov ax,@data
	mov ds,ax

	mov ax, 0h				;IVT's location  is '0000' adrees of RAM 
	mov es, ax
	
	
	;הרחבת פסיקה 
	cli						;block interrupts
	
	;moving int1Ch into IVT[080h]
	mov ax, es:[01Ch*4]		;copying old ISR IP to free vector
	mov es:[80h*4], ax
	mov ax, es:[01Ch*4+2]	;copying old ISR CS to free vector
	mov es:[80h*4+2], ax
	
	;moving ISR_NEW into IVT[1Ch]
	mov ax, offset ISR_NEW 	;copying IP of ISR_NEW to IVT[1Ch]
	MOV es:[01Ch*4]	, ax
	mov ax, cs				;copying CS of ISR_NEW to IVT[1Ch]
	mov es:[01Ch*4+2], ax
	
	sti						;enable interrupts
	
	;setting extra segment to screen memory
	mov ax ,0b800h
	mov es ,ax
	
	;black background
	mov bp, 0
	mov cx, 2000d					;counter
loop1:
	call BlackBackground			;the routine prints black cell
	add bp, 2						;move to next cell
	loop loop1
	
	;locate the player in the middle
	mov bp, 2000d
	call PrintPlayer
	
	;prints the first point
	call NewPoint		
	
	;cancel keyboard interrupt
	in  al, 21h 
	or  al, 02h 
	out 21h, al
	
	mov cl ,0
	
PollKeyboard:
	
	in al, 64h 
	test al, 01						;check if any key was pressed	
	jz NOW
	
	in al, 60h						;AL holds the scan code of the key
	mov cl, al
NOW:
	cmp counter, 0					;check if 3 entries passed for interrupt  
	jnz PollKeyboard
	
	call move						;send routine that moves player
	inc counter

	jmp PollKeyboard				;back to waiting for user to press key
	
	
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;routine deals with all 4 kind of moves - up, down, left, right
;if Q was pressed - finnish program 
;inputs:
;cl - scan code
;output:

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
move proc uses cx

	;exit
	cmp cl, 90h			;if key Q was pressed 
	jz stop
	;up
	cmp cl, 91h			;if key W was pressed
	jz up
	;down
	cmp cl, 9Fh			;if key S was pressed
	jz down
	;right
	cmp cl, 0A0h		;if key D was pressed
	jz right
	;left
	cmp cl, 9Eh			;if key A was pressed
	jz left
	
	ret					;any other key - nothing will happen
	
;if Q was pressed 
;print the score and exit the game
stop:
	mov al, score
	mov bl, 10
	mov ah, 0
	idiv bl			
	add ah, 48		;ascii value of tens
	add al, 48		;ascii value of ones 
	
	;update points in array
	mov bp, offset msg_score	
	mov ds:[bp+7], al
	mov ds:[bp+8], ah
	
	;printing points
	mov dx,offset msg_score		
	mov ah,9h
	int 21h
		
	;return power to keyboard
	mov al, 0
	out 21h, al
	
	
	;return interupts to place 	
	mov ax, 0h				;IVT's location  is '0000' adrees of RAM 
	mov es, ax
	
	cli						;block interrupts
	
	;moving int1Ch into IVT[080h]
	mov ax, es:[80h*4]		;copying old ISR IP to free vector
	mov es:[01Ch*4], ax
	mov ax, es:[80h*4+2]	;copying old ISR CS to free vector
	mov es:[01Ch*4+2], ax
	
	
	sti						;enable interrupts
	
	;סיים את התוכנית
	.exit					
	
;אם נלחץ W
up:
	cmp PlayerLocation, 160d	;if we are on the top row
	jl limit					;go back
	
	mov bp, PlayerLocation		
	call BlackBackground		;in the place the player was before we will color black 
	sub bp, 160d
	mov PlayerLocation, bp		
	call PrintPlayer			;print the player one row higher
	jmp point					;check if we have targeted the point 
	
;אם נלחץ S
down:
	cmp PlayerLocation, 3840d	;if we are on the bottom row
	jg limit					;go back
	
	mov bp, PlayerLocation		
	call BlackBackground		;in the place the player was before we will color black 
	add bp, 160d
	call PrintPlayer			;print the player one row below
	jmp point					;check if we have targeted the point 
	
;אם נלחץ A	
left:
	mov ax, PlayerLocation		;check if we are at the very left
	mov dx, 0
	mov bx, 160d
	idiv bx
	cmp dx, 0 
	jz limit
		
	mov bp, PlayerLocation		
	call BlackBackground		;in the place the player was before we will color black
	sub bp, 2d
	call PrintPlayer			;move the player one spot left
	jmp point					;check if we have targeted the point 

;אם נלחץ D
right:
	mov ax, PlayerLocation		;check if we are at the very right
	mov dx, 0
	mov bx, 160d
	idiv bx
	cmp dx, 158d 
	jz limit
		
	mov bp, PlayerLocation		
	call BlackBackground		;in the place the player was before we will color black
	add bp, 2d
	call PrintPlayer			;move the player one spot right
	jmp point					;check if we have targeted the point  


;if we have reached the edges - we wont move the player	
limit:
	ret

;if we have moved the player - we have to check if over rode the point
;if so, we have to print a new point
point:
	mov ax, PlayerLocation
	mov bx, PointLocation
	cmp ax, bx			;check if the player is at the same spot as the point
	jnz limit			;if not - exit
	call NewPoint		;if yes - new point 
	inc score			;update the score
	ret
	
move endp

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;the routine makes a new point at rando location and saves the current location
;outputs:
;new point on the screen
;PointLocation- current location
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
NewPoint proc 
start:
	mov al, 0h				;seconds	
	out 70h,al				
	in al,71h
	mov bh, al	
	
	mov al, 02h				;minutes
	out 70h,al			
	in al,71h	
	mov bl, al
	
	mov ax, bx
	
	;check if value is even
	mov bx, 2
	mov dx, 0
	div bx		
	mul bx
	
	;check if location is in range of the screen
	add ax, 3998d
locate:
	sub ax, 3998d
	cmp ax, 3998d			
	jg locate
	
	;check if new location is different from old location of point 
	mov bx, PointLocation
	cmp ax, bx
	jz start		;if new location is the same as old location - get a new location 
	
	;if not the same - print the new point 
	mov bp, ax
	mov PointLocation, ax
	mov al, 03h			;heart
	mov ah, 09h			;blue
	mov es:[bp], ax
	ret
NewPoint endp


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;the routine colores in black the square in location bp
;inputs:
;bp-the location that we print black backround
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BlackBackground proc
	mov al, 20h						;space ascii code
	mov ah, 0
	mov es:[bp], ax
	ret
BlackBackground endp

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;the routine places player in location bp
;updates the variable with location 
;inputs:
;bp- the location that we have to print the player
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PrintPlayer proc
	mov al, 2						;smiley ascii code
	mov ah, 12d						;red color
	mov es:[bp], ax
	mov PlayerLocation, bp			;save player location
	ret
PrintPlayer endp


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;extends the interruptions 
;updates the counter to number between 0-2 
;calls the original interuption
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ISR_NEW	 proc far uses ax es
	
	cmp counter, 2
	jz TWO
	inc counter
	jmp PREV_ISR
TWO:
	mov counter, 0
PREV_ISR:
	int 80h
	
	iret
ISR_NEW endp


end MAIN