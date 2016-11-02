TITLE	clock.asm

; Author: Eseosa Asiruwa
; Last update: October 30, 2016
;
; This program uses interuppt techniques, using a small model program that
; continously updates a real-time clock (hours, minutes, seconds) for as long
; as the program is running. When both shift keys are pressed, the clock is
; displayed on and off. Also, when the ctrl key is pressed, the clock toggles
; between 12-hour and 24-hour.


INCLUDE Irvine16.inc
.8086
.data

.code
time byte "0123456789"
colon byte ":"
hours byte 1 DUP(?)
minutes byte 1 DUP(?)
seconds byte 1 DUP(?)
rshift byte 0
lshift byte 0
showit byte 0
switch byte 0
hourx byte 0

OutClock PROC
	; STDCALL 16-bit value parameter
	; Output time in hr:min:secs depending on whether the user has
	; toggled for the clock to be in 12hr or 24hr format

	push bp			; Set up stack for retrieving parameter
	mov bp, sp

	push ax			; Push used registers to the stack
	push bx
	push cx
	push dx

	mov cx, 4		; Move 4 to CX for shifting
	mov ah, 0Eh		; Bios output routine

        push ax			; Save values that are in AX
	push cx			; and CX
        mov ah, 02h		; Move to AH the bios routine for getting time
        int 1Ah			; in BCD
	mov hours, ch		; The function returns hours in ch, min in cl,
	mov minutes, cl		; and secs in dh. Move these values into memory
	mov seconds, dh		; to be used in the function later
	pop cx			; Pop back the originals values to CX
        pop ax			; and AX

	cmp switch, 0		; Check if time should be shown in 12 or 24hr
	jne miltime		; If switch is 0FFh, then show in 24hr
	cmp hours, 12		; If 12, check if the current time is PM
	jl sethourx		; if its AM, jump to seperate instructions
	push ax			; but if it is, time must be adjusted, save AX
	mov al, hours		; Move current BCD hours to al
	sub al, 12h		; subtract 12h from hours and
	das			; new value is adjusted
	mov hours, al		; move new found value back to place in memory
	pop ax			; restore AX
	mov hourx, 1		; Adjust variable to reflect that time is in PM
	jmp checkhr		; Jump to checking for 0
sethourx:
	mov hourx, 0		; If the time is in AM, change variable to 0
checkhr:
	cmp hours, 0		; Check if current hour is 0
	jg miltime		; if it is greater, jump to printing time
	push ax			; If not, save AX to prepare for BCD adjust
	mov al, hours		; Move the current hours to AX
	add al, 12h		; Add 12h to current hours and
	daa			; the new value is adjusted
	mov hours, al		; Move new found value back to place in memory
	pop ax			; Restore AX register
miltime:
	push cx			; Save CX register
	mov cx, 4		; Move to CX 4 for shifting
	mov bl, hours		; Move current hours to bl for shifting
	shr bx, cl		; Shift to isolate first nybble

	mov al, 20h
	int 10h

	mov al, time[bx]	; Move found nybble character to al
	int 10h			; Print character to the screen
	mov bl, hours		; Move hours back to bl
	and bx, 000Fh		; Isolate the second nybble
	mov al, time[bx]	; Move second found nybble character to al
	int 10h			; Print character to screen

	mov al, colon		; Move colon character to al
	int 10h			; Print to screen

	mov bl, minutes		; Move current minutes to bl for shifting
	shr bx, cl 		; Shift to isolate first nybble
	mov al, time[bx]	; Move found nybble character to al
	int 10h 		; Print character to screen
	mov bl, minutes 	; Move minutes back to bl
	and bx, 000Fh  		; Isolate the second nybble
	mov al, time[bx] 	; Move second found nybble character to al
	int 10h 		; Print character to screen

	mov al, colon 		; Move colon character to al
	int 10h 		; Print to screen

	mov bl, seconds 	; Move current secs to bl for shifting
	shr bx, cl 		; Shift to isolate first nybble
	mov al, time[bx] 	; Move found nybble character to al
	int 10h 		; Print character to screen
	mov bl, seconds 	; Move secs back to bl
	and bx, 000Fh  		; Isolate the second nybble
	mov al, time[bx] 	; Move second found nybble character to al
	int 10h 		; Print character to screen

	cmp switch, 0 		; Check the clock is set to print in 24hr
	jne removeampm		; If it is jump to removing the AM/PM

	mov al, 20h 		; Move a space character to al
	int 10h			; Print a leading space for leading space

	cmp hourx, 0		; Check if time is in AM or PM
	jne printpm		; Jump to printing PM if variable is one
	mov al, 41h		; Move to al the character A
	int 10h			; Print character to the screen
	mov al, 4Dh		; Move to al the character M
	int 10h			; Print character to the screen
	jmp done		; Printing is finished, exit
printpm:			; If time is in PM
	mov al, 50h		; Move to al the character P
	int 10h			; Print character to the screen
	mov al, 4Dh		; Move to al the character M
	int 10h			; Print character to the screen
	jmp done		; Printing is finished, exit

removeampm:			; Remove remenents of 12 hour time
	push cx			; Save value in CX
	mov cx, 4		; Move to CX number of spaces to write
	mov al, 20h		; Move al the space character
	remove:			; Create loop for printing space
	  int 10h		; Call bios instruction to print
	  loop remove
done:
	pop dx			; Restore all registers
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

OutClockCorner PROC
	; IN: 16 bit parameter
        ; [bp+4] count

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

	mov dh, 0			; Set the row and column
	mov dl, 67
	call JumpCursor
continue:
	push [bp + 4]			; Output the parameter
	call OutClock
done:
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

orig_09 dword ?
orig_08 dword ?
count word ?

handle08 PROC
	add count, 55			; Adding to get time every 55 milisecs
	cmp  count, 1000		; Checking if count has reached a sec
	jle done			; if it hasnt, dont get the time
	sub count, 1000			; if it has, subtract to reset counter
continue:				; and print clock
	cmp showit, 0			; Check to see whether to show clock
	jne clear			; if showit is not 1, then clear clock
	push count			; if not push the count parameter
	call OutClockCorner		; and display the clock
	jmp done			; when clock is displayed, you're done
clear:
	call clear_clock		; Clock is toggled to not display
done:
	pushf				; Push flags and return to where you
	call orig_08			; were before interrupt
	iret
handle08 ENDP

handle09 PROC
	pushf
	call orig_09			; handle the keyboard interrupt!
					; This is an indirect far call
	push ax
	mov ah, 0
	in al, 60h			; Read the current key

ctrld:					; First check to see if ctrl pressed
	cmp al, 9Dh			; If it was not released
	jne rightdown			; jump to next check point
	not switch			; if it was, change variable
	jmp done			; exit from function
rightdown:
	cmp al, 36h 			; Check for rshift pressed down
	jne rightup			; if it was not pressed, jump to next
	mov rshift, 1			; if it was, change rshift variable
	jmp check			; jump to checking both shifts
rightup:
	cmp al, 0B6h			; Check for rshift released
	jne leftdown			; if it was not released, jump to next
	mov rshift, 2			; if it was change rshift var again
	jmp check			; jump to checking both shifts
leftdown:
	cmp al, 2Ah			; Check for lshift pressed down
	jne leftup			; if it was not pressed, jump to next
	mov lshift, 1			; if it was, change lshift var
	jmp check			; jump to checking both shifts
leftup:
	cmp al, 0AAh			; Check for lshift released
	jne other			; if it was not released, jump to next
	mov lshift, 2			; if it wasm change lshift var
	jmp check			; jump to checking both shifts
other:
	mov lshift, 0			; If neither left or right shifts were
	mov rshift, 0			; pressed and released at the same time
	jmp done			; set the both to 0 and exit
check:
	cmp lshift, 1			; Check to see if left was pressed
	jne done			; if not exit
	cmp rshift, 1			; Check to see if right was pressed
	jne done			; if not exit
display:
	not showit			; if it was toggle is initiated
done:
	pop ax
	iret				; return to the point of interrupt
handle09 ENDP

clear_clock PROC
	push ax				; Push used registers to stack
	push bx
	push cx
	push dx

	mov bh, 0			; Move to bh the page number
	mov ax, 0300h			; Use bios function to move the
	int 10h				; position of the cursor
	push dx				; save current cursor position

	mov dh, 0			; Set row
	mov dl, 67			; set column
	call JumpCursor			; move cursor to top right
	mov ah, 0Eh			; prepare ax for printing
	mov al, 0
	mov cx, 12			; move to cx number of spaces to print
	space:
	  mov al, 20h			; move space character to al
	  int 10h			; print 11 spaces
	  loop space

	pop dx				; pop back original cursor position
	call JumpCursor			; move cursor back to orginal position

	pop dx				; Pop back used registers and return
	pop cx
	pop bx
	pop ax
	ret
clear_clock ENDP

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
	mov word ptr orig_09, bx
	mov word ptr orig_09+2, es

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
	mov word ptr orig_08, bx
	mov word ptr orig_08+2, es

	; Now install the new 08 vector
	push cs				; put our code segment
	pop ds				; into ds
	mov dx, offset handle08		; with offset in dx
	mov ax, 2508h
	int 21h

	pop dx
	pop bx
	pop ax
	pop es
	pop ds
	ret
install08 ENDP

uninstall09 PROC
	;; restore the original int 09h vector
	push ds
	push ax
	push dx

	mov dx, word ptr orig_09
	mov ds, word ptr orig_09 + 2
	mov ax, 2509h
	int 21h

	pop dx
	pop ax
	pop ds
	ret
uninstall09 ENDP

uninstall08 PROC
	;; restore the original int 09h vector
	push ds
	push ax
	push dx

	mov dx, word ptr orig_08
	mov ds, word ptr orig_08 + 2
	mov ax, 2508h
	int 21h

	pop dx
	pop ax
	pop ds
	ret
uninstall08 ENDP

main PROC
.data
inputstr BYTE 255 DUP(0)
.code
	mov ax, @data
	mov ds, ax

	mov dx, offset inputstr
	mov bx, dx
	mov cx, lengthof inputstr

	; install handle09 as the new interrupt vector for int 09h.
	call install09
	call install08
	; done with install

top:
					; read strings and echo them until 
	call readstring			; user enters an empty string
	call crlf
	cmp byte ptr [bx], 0
	je done
	call WriteString
	call crlf
	jmp top

done:
	call uninstall08
	call uninstall09

	mov ax, 4c00h
	int 21h

main ENDP
END main



