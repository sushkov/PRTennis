;====================== Main procedures ====================

;---------------------- Main procedure ---------------------
Main_proc proc
	call Hide_cursor 
	call Save_mainscr ;Save screen 
		
Main_page:	
	call Draw_main_frame ;Draw intro page 
		
Next_key:
	call Wait_key
	or al,al
    jz short Ext_code  ;It is extended ASCII-code?
	
	cmp al,27 ;Is Esc pressed?
	je Quit_prg	
	jmp short Next_key
		
Ext_code:
	cmp ah,3Bh ;Is F1 pressed?
	je short F1_pressed
	
	cmp ah,3Ch ;Is F2 pressed?
	je short F2_pressed
	jmp short Next_key
	
;F2_pressed ---------------------
F2_pressed:
	call Draw_about_frame
Next_key_abpg:	
	call Wait_key
	or al,al
    jz short Ext_code_abpg  ;It is extended ASCII-code?
	
	cmp al,27 ;Is Esc pressed?
	je Quit_prg_abpg
	jmp short Next_key_abpg
	
Ext_code_abpg:
	cmp ah, 3Ch
	je Main_page
	jmp short Next_key_abpg
	
;F1_pressed ---------------------
F1_pressed:
	call Draw_game_frame
	call Set_platforms
Next_key_game:	
	call Wait_key
	or al,al
    jz short Ext_code_game  ;It is extended ASCII-code?
	
	cmp al,50h ;Is 'P' pressed?
	je Pause_prg
	
	cmp al,70h ;Is 'p' pressed?
	je Pause_prg
	
	cmp al,66h ;Is 'f' pressed?
	je Finish_prg
	
	cmp al,46h ;Is 'F' pressed?
	je Finish_prg
	
	cmp Start_game,0
	je Out_game
	
	cmp al,6Ch 
	je L_pressed
	jmp Next_key_game
	
Out_game:	
	cmp al,13 ;Is 'Enter' pressed?
	je Start_ball

Start_ball:	
	call Set_int08h
	mov Start_game,1
	jmp Next_key_game
Ext_code_game:
	cmp ah,4Bh ;Is left cursor-button pressed?
	je Move_left
	
	cmp ah,4Dh ;Is right-button pressed?
	je Move_right
	
	jmp Next_key_game
;---------------------------
L_pressed:
;Тут обработка и контроль движения шара
	pusha
	push es
	call Calc_next_step
	cmp dx,0ACDCh
	je Game_over_prg
	cmp Curr_score,999
	je Win_prg
	
	call Move_ball
	pop es
	popa
	jmp Next_key_game
;---------------------------
Move_left:
	call Move_left_prog
	jmp Next_key_game
	
Move_right:
	call Move_right_prog
	jmp Next_key_game
;---------------------------
Finish_prg:
	cmp Start_game,0
	je Out_game_finish
	call Restore_int08h
Out_game_finish:	
	call Finish_prog
	jnc Next_key_game
	mov Game_speed_count,0
	mov Start_game,0
	jmp Main_page	
;---------------------------
Pause_prg:
	cmp Start_game,0
	je Out_game_pause
	call Restore_int08h
Out_game_pause:	
	call Pause_prog
	jmp Next_key_game
;---------------------------
Game_over_prg:
	pop es
	popa
	call Restore_int08h
	call Game_over_prog
	mov Start_game,0
	jmp Main_page
;---------------------------
Win_prg:
	pop es
	popa
	call Restore_int08h
	call Win_prog
	mov Start_game,0
	jmp Main_page
;---------------------------
Quit_prg:
      call Quit_prog ;Подтвердим намерения пользователя выйти из программы.
      jnc Next_key   ;Пользователь подтвердил выход? НЕТ? Тогда на Next_key 
	  jmp Quit	

Quit_prg_abpg:
      call Quit_prog ;Подтвердим намерения пользователя выйти из программы.
      jnc Next_key_abpg   ;Пользователь подтвердил выход? НЕТ? Тогда на Next_key 

Quit:
      call Restore_mainscr ;восстановим содержимое экрана
      call Restore_cursor  ;восстановим позицию курсор
      ret ;Выходим из процедуры MAIN.ASM, а затем сразу в DOS!
	  
Main_proc endp

;--------- Hide cursor, saved its current position ---------
Hide_cursor proc
	;Get current position of cursor and save it
	mov ah,3
	mov bh,Video_page
	int 10h
	mov Pos_cursor,dx
	
	;Set cursor on first video page
	mov ah,2
	mov bh,1
	int 10h
	
	;Hide cursor on zero video page
	mov bh,Video_page
	mov dx,1900h ;
	int 10h
	
	ret
Hide_cursor endp

;------------------ Draw main frame -------------------------
;Draw intro page
Draw_main_frame proc
	call Clear_screen

	push 23
	push 78
	push Main_color
	push offset Main_msg_up
	push offset Main_msg_down
	push offset Main_msg_ins
	push Num_main_rows
	push 0b
	call Draw_frame ;Draw full-screen frame
	ret
Draw_main_frame endp

;------------------ Draw about frame -------------------------
;Draw about page
Draw_about_frame proc
	call Clear_screen
	
	push 23
	push 78
	push Main_color
	push offset About_msg_up
	push offset About_msg_down
	push offset About_msg_ins
	push Num_about_rows
	push 0b
	call Draw_frame ;Draw full-screen frame
	ret
Draw_about_frame endp

;------------------ Draw game frame -------------------------
;Draw game page
Draw_game_frame proc
	call Clear_screen
	
	push 23
	push 78
	push Main_color
	push offset Game_msg_up
	push offset Game_msg_down
	push offset 0
	push 0
	push 0b
	call Draw_frame ;Draw full-screen frame
	ret
Draw_game_frame endp

;---------------------- Ждем нажатия клавиши --------------------
Wait_key proc
      xor ah,ah
      int 16h
      ret
Wait_key endp

;-------------------------------- Восстановим курсор ------------
Restore_cursor proc
    mov ah,2
    mov bh,Video_page ;видеостраница
    mov dx,Pos_cursor ;сохраненная позиция
    int 10h           ;установим (позиционируем) курсор
    ret
Restore_cursor endp

;--------------------------------- Выходим из программы? -------------
Quit_prog proc
      push 1
      push offset Mess_quitl
      push 4F00h
      push offset Mess_qup
      push 0
      push offset Mess_quit
	  push Num_exit_rows
      push 1b
      call Draw_frame

      call Wait_key
      call Restore_scr ;Восстановим сохранунную часть экрана.

      cmp al,'Y'       ;Нажали 'Y' / 'y' / Enter (13)?
      je Yes_quit      ;Да! 
      cmp al,'y'
      je Yes_quit
      cmp al,13
      je Yes_quit

      clc
      ret

Yes_quit:
      stc  ;Установим флаг переноса (нажали 'Y', значит выходим)...
      ret
Quit_prog endp

;--------------------------------- Finish program -------------
Finish_prog proc
      push 1
      push offset Mess_finishl
      push 4F00h
      push offset Mess_fup
      push 0
      push offset Mess_finish
	  push 1
      push 1b
      call Draw_frame

      call Wait_key
      call Restore_scr ;Восстановим сохранунную часть экрана.

      cmp al,'Y'       ;Нажали 'Y' / 'y' / Enter (13)?
      je Yes_finish      ;Да! 
      cmp al,'y'
      je Yes_finish
      cmp al,13
      je Yes_finish

	cmp Start_game,0
	je Out_game_finish_exit
	  call Set_int08h
Out_game_finish_exit:
      clc
      ret

Yes_finish:
      stc  ;Установим флаг переноса (нажали 'Y', значит выходим)...
      ret
Finish_prog endp
;--------------------------------- Pause program -------------
Pause_prog proc
      push 1
      push offset Mess_pausel
      push 4F00h
      push offset Mess_pup
      push 0
      push offset Mess_pause
	  push 1
      push 1b
      call Draw_frame

Next_key_pause:
      call Wait_key
      
      cmp al,'P'
      je Exit_pause       
      cmp al,'p'
      je Exit_pause
      	  	
      jmp Next_key_pause
	  
Exit_pause:
	cmp Start_game,0
	je Out_game_pause_exit
	  call Set_int08h
Out_game_pause_exit:
	  call Restore_scr ;Restore part of main screen
      ret
Pause_prog endp

;--------------------------------- Game over program -------------
Game_over_prog proc
      push 1
      push offset Mess_game_overl
      push 4F00h
      push offset Mess_g_oup
      push offset Mess_g_odown
      push offset Mess_game_over
	  push 1
      push 1b
      call Draw_frame

Game_over_next_key:	  
    call Wait_key
     
    cmp al,0
	je Ext_code_game_over
	  
    cmp al,13 ;Is 'Enter' pressed?
    je Game_over_finish
	jmp Game_over_next_key

Ext_code_game_over:
	cmp ah,3Bh ;Is F1 pressed? 
	je Game_over_finish
	jmp Game_over_next_key

Game_over_finish:
	ret
Game_over_prog endp

;--------------------------------- Win program -------------
Win_prog proc
      push 1
      push offset Mess_winl
      push 4F00h
      push offset Mess_winup
      push offset Mess_windown
      push offset Mess_win
	  push 1
      push 1b
      call Draw_frame

Win_next_key:	  
    call Wait_key
     
    cmp al,0
	je Ext_code_win
	  
    cmp al,13 ;Is 'Enter' pressed?
    je Win_finish
	jmp Win_next_key

Ext_code_win:
	cmp ah,3Bh ;Is F1 pressed? 
	je Win_finish
	jmp Win_next_key

Win_finish:
	ret
Win_prog endp
;---------------------------- Set int 08h -------------------------
Set_int08h proc
	push es
	push bx
	
	mov ax,3508h
	int 21h
	
	mov word ptr Int_08h_vect,bx
	mov word ptr Int_08h_vect+2,es
	
	mov ax,2508h
	mov dx,offset Int_08h_proc
	int 21h
	
	pop bx
	pop es
	ret
Set_int08h endp

;---------------------------- Restore int 08h ----------------------
Restore_int08h proc
	push ds
	push dx
	
	mov ax,2508h
	mov dx,word ptr Int_08h_vect
	mov ds,word ptr Int_08h_vect+2
	int 21h
	
	pop dx
	pop ds
	ret
Restore_int08h endp
;---------------------------- Int08h program -----------------------
Int_08h_proc proc
	cmp Game_speed_count,05h ;Speed 0 - maximum 
	je Reset_counter
	
	inc Game_speed_count
	jmp Go_int08h
	
Reset_counter:
	mov Game_speed_count,0
	
	pusha
	mov ah, 05h
    mov cx, 'l'
    int 16h
	popa

Go_int08h:	
	jmp dword ptr cs:[Int_08h_vect]
Int_08h_proc endp

;--------------------------- Calculate next ball position ----------
;Input: Ball_pos_curr, Ball_pos_pred
;Output: DX - next position of ball
Calc_next_step proc
	
	mov ax,Ball_pos_curr
	mov bx,Ball_pos_pred
	mov cx,Curr_pos
	
;Check platforms and up/down borders
	cmp ah,1
	je Game_over
	
	cmp ah,23
 	je Game_over
	
	cmp ah,2
	je Up_border
	
	cmp ax,bx
	je Start_ball
	
	cmp ah,22
	je Down_border
	
;Check borders	
	cmp al,1
	je Left_border
	
	cmp al,78
	je Right_border
	
;If ball in the game field
Ball_in_game:
	cmp ah,bh ;Current position < previous position?
	ja Ball_down
	
	cmp ah,bh ;Current position = previous position?
	je Ball_horizontal
	
;Current position > previous position	
;Ball move up
	dec ah
	mov dh,ah

Check_l_r:	
	cmp al,bl
	ja To_right
	
	cmp al,bl
	jb To_left
	
;To vertical
	mov dl,al
	ret
	
Ball_down:
	inc ah
	mov dh,ah
	jmp Check_l_r

Ball_horizontal:
	mov dh,ah
	jmp Check_l_r

To_left:
	dec al
	mov dl,al
	ret
	
To_right:
	inc al
	mov dl,al
	ret
;-------------------------------------------------------
;TEMP Start ball
Start_ball:
	dec ah
	inc al
	mov dx,ax
	ret
;-------------------------------------------------------
;Ball move near left border
Left_border:
	cmp ah,bh ;Current position < previous position?
	ja Ball_down_left
	
	cmp ah,bh ;Current position = previous position?
	je Horizontal_left
	
;Current position > previous position	
;Ball move up
	dec ah
	mov dh,ah
	
	cmp al,bl
	je Vertical_left
	
;Ball move up at an angle to the border
	jmp At_angle_left	
	
	
Ball_down_left:
;Ball move down
	inc ah
	mov dh,ah

	cmp al,bl
	je Vertical_left
	
;Ball move down at an angle to the border
At_angle_left:	
	inc al
	mov dl,al
	ret
	
Vertical_left:
;Ball move vertical down
	mov dl,al
	ret
	
Horizontal_left:
;Ball move horizontal to left border
	mov dh,ah
	inc al
	mov dl,al
	ret
;---------------------------------------------------------
;Ball move near right border
Right_border:
	cmp ah,bh ;Current position < previous position?
	ja Ball_down_right
	
	cmp ah,bh ;Current position = previous position?
	je Horizontal_right
	
;Current position > previous position	
;Ball move up
	dec ah
	mov dh,ah
	
	cmp al,bl
	je Vertical_right
	
;Ball move up at an angle to the border
	jmp At_angle_right	
	
	
Ball_down_right:
;Ball move down
	inc ah
	mov dh,ah

	cmp al,bl
	je Vertical_right
	
;Ball move down at an angle to the border
At_angle_right:	
	dec al
	mov dl,al
	ret
	
Vertical_right:
;Ball move vertical down\up
	mov dl,al
	ret
	
Horizontal_right:
;Ball move horizontal to right border
	mov dh,ah
	dec al
	mov dl,al
	ret
;---------------------------------------------------------
;Ball move near up border
Up_border:
	cmp cl,al ;al >= cl?
	jbe Below_up
	jmp Ball_in_game
	
Below_up:	
	add cl,11
	cmp al,cl ;al <= cl?
	jbe Norm_up
	jmp Ball_in_game
	
Norm_up:
	inc Curr_score
	call Display_score
	
	inc ah
	mov dh,ah
	
	cmp al,bl
	jb To_left_up 
	
	cmp bl,al
	jb To_right_up
	
;If ball move vertical
Vertical_up:
	mov dl,al
	ret
	
To_left_up:	
	dec al
	mov dl,al
	ret
	
To_right_up:
	inc al
	mov dl,al
	ret
;---------------------------------------------------------
;Ball move near down border
Down_border:
	cmp cl,al ;al >= cl?
	jbe Below_down
	jmp Ball_in_game
	
Below_down:	
	add cl,11
	cmp al,cl ;al <= cl?
	jbe Norm_down
	jmp Ball_in_game
Norm_down:
	inc Curr_score
	call Display_score
	
	dec ah
	mov dh,ah
	
	cmp al,bl
	jb To_left_up
	
	cmp bl,al
	jb To_right_up
	jmp Vertical_up

;---------------------------------------------------------
Game_over:
	mov dx,0ACDCh
	ret
;---------------------------------------------------------	
Calc_next_step endp