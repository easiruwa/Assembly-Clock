TITLE clocktsr

; Author: Eseosa Asiruwa
; Last update: October 30, 2016

; TSR (Terminate, Stay Resident)
; This program builds off of the small model clock program but is instead,
; a tiny model that installs a resident routine so that the clock is updated
; continously until the machine is rebooted. This program also makes sure that
; other pgrams can run properly in the presence of this TSR

.8086
.model tiny

.code

	org	100h

top:	jmp	start


time byte "0123456789"
colon byte ":"
hours byte 1 DUP(?)
minutes byte 1 DUP(?)
seconds byte 1 DUP(?)
rshift byte 0
lshift byte 0
switch byte 0
hourx byte 0

OutClock PROC
	; STDCALL 16-bit value parameter
	; Output time in hr:min:secs depending on whether the user has toggled
	; for the clock to be in 12hr or 24hr format

	push bp				; Set up stack for retrieving parameter
	mov bp, sp

	push ax				; Pushed used registers to the stack
	push bx
	push cx
	push dx

	mov	cx, 4			; Move 4 to CX for shifting
	mov	ah, 0Eh			; Bios output routine

	push ax				; Save values that are in AX
	push cx				; and CX
	mov ah, 02h			; Move to ah bios routine to get time
	int 1Ah				; in BCD
	mov cs:[hours], ch		; The function returns hours in ch, min
	mov cs:[minutes], cl		; in cl, and secs in dh. Move these 
	mov cs:[seconds], dh		; values into mem to be used later
	pop cx				; Pop back orginal values to CX
	pop ax				; and ax

	cmp cs:[switch], 0		; Check if time is shown in 12hr or 24
	jne miltime			; If switch is 0FFh, show in 24hr
	cmp cs:[hours], 12		; If 12hr, check if current time is PM
	jl sethourx			; if its AM, jump to seperate instrc
	push ax				; if it is, time must be adjusted
	mov al, cs:[hours]		; Move current BCD hours to al
	sub al, 12h			; subtract 12h from hours and
	das				; new value is adjusted
	mov cs:[hours], al		; move new found val back to mem
	pop ax				; restore AX
	mov cs:[hourx], 1		; Adjust var to reflect that time in PM
	jmp checkhr			; Jump to check for 0
sethourx:
	mov cs:[hourx], 0		; If the time is AM, change var to 0
checkhr:
	cmp cs:[hours], 0		; Check if current hour is 0
	jg miltime			; If it is greater, jump to print time
	push ax				; If not, save AX to prepate for adjust
	mov al, cs:[hours]		; Move current hours to AX
	add al, 12h			; Add 12h to current hours and
	daa				; the new value is adjusted
	mov cs:[hours], al		; Move new found val back to memory
	pop ax				; Restore AX register
miltime:
	push cx				; Save CX register
	mov cx, 4			; Move to CX 4 for shifting
	mov bl, cs:[hours]		; Move current hrs to bl for shifting
	shr bx, cl			; Shift to isolate first nybble

	mov al, 20h
	int 10h

	mov al, cs:time[bx]		; Move found nybble char to al
	int 10h				; Print char to screen
	mov bl, cs:[hours]		; Move hours back to bl
	and bx, 000Fh			; Isolate second nybble
	mov al, cs:time[bx]		; Move second nybble char to al
	int 10h				; Print char to screen

	mov al, cs:[colon]		; Move colon char to al
	int 10h				; Print char to screen

	mov bl, cs:[minutes]		; Move current mins to bl for shifting
	shr bx, cl			; Shift to isolate first nybble
	mov al, cs:time[bx]		; Move found nybble char to al
	int 10h				; Print char to screen
	mov bl, cs:[minutes]		; Move minutes back to bl
	and bx, 000Fh			; Isolate second nybble
	mov al, cs:time[bx]		; Move second found nybble char to al
	int 10h				; Print char to screen

	mov al, cs:[colon]		; Move colon char to al
	int 10h				; Print to screen

	mov bl, cs:[seconds]		; Move current secs to bl for shifting
	shr bx, cl			; Shift to isolate first nybble
	mov al, cs:time[bx]		; Move found nybble char to al
	int 10h				; Print char to screen
	mov bl, cs:[seconds]		; Move secs back to bl
	and bx, 000Fh			; Isolate second nybble
	mov al, cs:time[bx]		; Move second found nybble char to al
	int 10h				; Print char to screen

	cmp cs:[switch], 0		; Check the clock to see if it is 24hr
	jne removeampm			; If it is jump to removing AM/PM

	mov al, 20h			; Move a space char to al
	int 10h				; Print char to screen

	cmp cs:[hourx], 0		; Check if time is in AM or PM
	jne printpm			; Jump to printing PM if var is one
	mov al, 41h			; Move to al the char A
	int 10h				; Print char to the screen
	mov al, 4Dh			; Move to al the char D
	int 10h				; Print char to the screen
	jmp done			; Printing is done, exit
printpm:
	mov al, 50h			; Move to al the char P
	int 10h				; Print char to the screen
	mov al, 4Dh			; Move to al the char M
	int 10h				; Print char to the screen
	jmp done			; Printing is done, exit
removeampm:				; Remove remenents of 12 hour time
	push cx				; Save value in CX
	mov cx, 4			; Move to CX num of spaces to write
	mov al, 20h			; Move al, the space char
	remove:				; Create loop for printing space
	  int 10h
	  loop remove			; Call bios instruction to print
done:
	pop dx				; Restore all registers
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 2
OutClock ENDP

JumpCursor PROC
	; IN: DH row, DL column
	; Move the cursor on page 0.
	push ax
	push bx
	mov bh, 0
	mov ax, 0200h
	int 10h
	pop bx
	pop ax
	ret
JumpCursor ENDP

OutClockLoc PROC
	; IN: 16 bit location [bp + 4]
	; IN  16 bit value [bp + 6]
	; (STDCALL)
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx

 	mov bh, 0
	mov ax, 0300h		; get cursor position
	int 10h
	push dx			; remember it

	mov dx, [bp + 4]
	call JumpCursor

	push [bp + 6]		; output the parameter
	call OutClock

	pop dx			; move the cursor back!
	call JumpCursor

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 4
OutClockLoc ENDP

OutClockCorner PROC
	; IN: 16 bit parameter
	push bp
	mov bp, sp

	push ax				; Push used registers to the stack
	push bx
	push cx
	push dx

 	mov bh, 0
	mov ax, 0300h			; Get cursor position
	int 10h
	push dx				; Remember it

	mov dh, 0			; Set row and column
	mov dl, 67
	call JumpCursor
	push [bp + 4]			; Output the parameter
	push dx
	call OutClockLoc

	pop dx				; Move the cursor back!
	call JumpCursor

	pop dx				; Restore registers
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 2
OutClockCorner ENDP

orig_08 dword ?
orig_09 dword ?
counter word 0
showit	byte 0

handle08 PROC
	pushf				; Push flags
	call cs:[orig_08]

	add cs:[counter], 55		; Adding to get time every 55 milisecs
	cmp cs:[counter], 1000		; Check if count has reached a sec
	jle done			; if it hasnt, dont get the time
	sub cs:[counter], 1000		; if it has, subtract to reset counter
continue:				; and print clock
	cmp cs:[showit], 0		; Check to see whether to show clock
	jne clear			; if showit is not 1, then clear clock
	push cs:[counter]		; if not push the count parameter
	call OutClockCorner		; and display the clock
	jmp done			; when the clock is displayed, exit
clear:
	call clear_clock		; clock is toggled not to display
done:
	iret				; return to where you were before intr
handle08 ENDP

handle09 PROC
	push ax
	pushf				; To simulate an interrupt
	call cs:[orig_09]
	mov ax, 0
	in al, 60h			; Read the current key

ctrld:					; First check to see if ctrl pressed
	cmp al, 9Dh			; If it was not released
	jne rightdown			; jump to next check point
	not cs:[switch]			; if it was, change variable
	jmp done			; exit function
rightdown:
	cmp al, 36h			; check for rshift pressed down
	jne rightup			; if it was not pressed, jmp to next
	mov cs:[rshift], 1		; it it was, change rshift var
	jmp check			; jmp to checking both shifts
rightup:
	cmp al, 0B6h			; check for rshift released
	jne leftdown			; if it was not released, jump to next
	mov cs:[rshift], 2		; if it was change rshift var again
	jmp check			; jump to checking both shifts
leftdown:
	cmp al, 2Ah			; check for lshift pressed down
	jne leftup			; if it was not pressed, jmp to next
	mov cs:[lshift], 1		; if it was, change lshift var
	jmp check			; jump to checking both shifts
leftup:
	cmp al, 0AAh			; check for lshift released
	jne other			; if it was not released, jmp to next
	mov cs:[lshift], 2		; if it was change lshift var
	jmp check			; jmp to checking both shifts
other:
	mov cs:[lshift], 0		; if neither left or right were pressed
	mov cs:[rshift], 0		; and released at the same time
	jmp done			; set both to 0 and exit
check:
	cmp cs:[lshift], 1		; check to see if left was pressed
	jne done			; if not exit
	cmp cs:[rshift], 1		; check to see if right was pressed
	jne done			; if not exit
display:
	not cs:[showit]			; if it was toggle is initiated
done:
	pop ax				; return to the point of interrupt
	iret
handle09 ENDP


clear_clock PROC
	push ax				; Push used registeres to stack
	push bx
	push cx
	push dx

	mov bh, 0			; Move to bh the page number
	mov ax, 0300h			; use bios function to move the
	int 10h				; position of the cursor
	push dx				; save the current cursor position

	mov dh, 0			; set row
	mov dl, 67			; set column
	call JumpCursor			; move cursor to top right
	mov ah, 0Eh			; prepare ax for printing
	mov al, 0
	mov cx, 12			; move to cx number of spaces to print
space:
	mov al, 20h			; move space char to al
	int 10h				; print 11 spaces
	loop space

	pop dx				; pop back orginal cursor position
	call JumpCursor			; move cursor back to orginal position

	pop dx				; Pop back registers and return
	pop cx
	pop bx
	pop ax
	ret
clear_clock ENDP


;   END OF RESIDENT PORTION!!!!!!!!!!!!!!!!!!!!!!!!
install:

install08 PROC
 	push ds
	push es
	push ax
	push bx
	push dx

	; before changing the vector, 
	; get the old vector and save it!
	mov ax, 3508h
	int 21h
	mov word ptr cs:[orig_08], bx
	mov word ptr cs:[orig_08+2], es

	; Now install the new 08 vector
	push cs				; put our code segment
	pop ds				; into ds
	mov dx, offset handle08		; with offset in dx
	mov ax, 2508h			; 
	int 21h

	pop dx
	pop bx
	pop ax
	pop es
	pop ds
	ret
install08 ENDP

install09 PROC
 	push ds
	push es
	push ax
	push bx
	push dx

	; before changing the vector, 
	; get the old vector and save it!
	mov ax, 3509h
	int 21h
	mov word ptr cs:[orig_09], bx
	mov word ptr cs:[orig_09+2], es

	; Now install the new 09 vector
	push cs				; put our code segment
	pop ds				; into ds
	mov dx, offset handle09		; with offset in dx
	mov ax, 2509h
	int 21h

	pop dx
	pop bx
	pop ax
	pop es
	pop ds
	ret
install09 ENDP

start:
	call install08
	call install09

	mov dx, 0
	mov dx, offset install
	mov cl, 4
	shr dx, cl			; dx is bytes / 16
	inc dx				; dx is paragraphs to reserve
	mov ax, 3100h
	int 21h

	;mov ax, 4c00h
	;int 21h

END top




