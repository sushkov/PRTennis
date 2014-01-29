.386
.287
CSEG segment use16
assume cs:CSEG, ds:CSEG, es:CSEG, ss:CSEG
org 100h

Start_prog:
	jmp Begin
	
	;=========== Procedures ============
	;Main procedure
	include main.asm
	
	;Display procedures
	include display.asm
	
	;Messages
	include messages.asm

	;Data
	include data.asm
	
	; Program begin
Begin:
	call Check_video
	call Main_proc
	
	int 20h

Finish equ $

CSEG ends
end Start_prog