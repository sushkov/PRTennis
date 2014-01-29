;============================= Data ================================
Video_page db 0 ;Current video page
Pos_cursor dw ? ;Main cursor position
Num_DX dw ?
Curr_pos dw ? ;Current position of platform
Ball_pos_curr dw ? ;Current position of ball
Ball_pos_pred dw ?
Num_main_rows dw 2 ;Number of text rows on main page 
Num_about_rows dw 4 ;Number of text rows on about page
Num_exit_rows dw 1 ;Number of text rows on exit dialog
Curr_score dw 0 ;Current score
Start_game db 0 ;1 - game, 0 - no game


Int_08h_vect dd ?

Game_speed_count db 0

;Data for Draw_frame procedure
Height_X equ [bp+14] ;Height
Width_Y  equ [bp+12] ;Width
Attr     equ [bp+10]  ;Attribute of frame
Mess_up  equ [bp+8]  ;Up message
Mess_dn  equ [bp+6]  ;Down message
Mess_ins equ [bp+4]  ;Message into frame
Num_rows equ [bp+2]  ;Number of text rows
Other    equ [bp]    ;Other configuration of frame