;========================= Configuration file ============================
Main_color dw 1F00h

Main_msg_up db 1Eh,' ProstoTennis ',0
Main_msg_down db 1Dh,' F1 - new game === F2 - about === Esc - exit ',0
Main_msg_ins db 1Eh,' Welcom to ProstoTennis!', 54 dup (20h),0
			 db ' Press F1 and go ...', 58 dup (20h),0
			 
About_msg_up db 1Eh,' About ',0
About_msg_down db 1Dh,' F1 - new game === F2 - return === Esc - exit ',0
About_msg_ins db 1Eh,' Prosto Tennis is easy game for DOS',43 dup (20h),0
			  db ' Purpose of this game is score points controlling the mobile platform and not',20h,0
			  db ' giving the ball fall',57 dup (20h),0
			  db ' Author: Vladimir Sushkov',53 dup (20h),0
			  
Game_msg_up db 1Eh,' Score:000 ',0
Game_msg_down db 1Dh,' P - pause === F - finish === Enter - start game ',0
			  
Mess_qup db 4Eh, ' Quit ',0
Mess_quit db 4Bh, ' Are you realy want to exit to DOS (Y/N)?',0
Mess_quitl equ $-Mess_quit-1 ;Один байт занимает код цвета (4Bh)

Mess_fup db 4Eh, ' Finish ',0
Mess_finish db 4Bh, ' Are you realy want to finish game (Y/N)?',0
Mess_finishl equ $-Mess_finish-1 ;Один байт занимает код цвета (4Bh)

Mess_pup db 4Eh, ' Pause ',0
Mess_pause db 4Bh, ' Game paused. Press P for return in game. ',0
Mess_pausel equ $-Mess_pause-1 ;Один байт занимает код цвета (4Bh)

Mess_g_oup db 4Eh, ' Game over ',0
Mess_g_odown db 4Eh, ' F1 - return to home page ',0
Mess_game_over db 4Bh, ' You lost, try again and you are lucky. ',0
Mess_game_overl equ $-Mess_game_over-1 ;Один байт занимает код цвета (4Bh)


Mess_winup db 4Eh, ' Congratulations ',0
Mess_windown db 4Eh, ' F1 - return to home page ',0
Mess_win db 4Bh, ' You have the highest score! ',0
Mess_winl equ $-Mess_win-1 ;Один байт занимает код цвета (4Bh)
