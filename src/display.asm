;====================== Display procedures ====================

;---------------- Check video mode and video page -------------
;We must set text mode and zero page
Check_video proc
	mov ah, 0Fh
	int 10h
	cmp al,3 ;It is text mode?
	je Ok_video
	
	mov ax,3
	int 10h
	
Ok_video:
	or bh,bh ;Zero page?
	jz Ok_page
	
	;Set zero page
	mov ax,0500h
	int 10h
	
Ok_page:
	ret
Check_video endp

;----------------------- Save screen --------------------------
Save_mainscr proc
	;Save registers
	pusha
	push es
	push ds
	
	;B800:0000 - zero video page
	push 0B800h
	pop ds
	xor si,si
	
	;B900:0000 - first video page
	push 0B900h
	pop es
	xor di,di
	
	mov cx,2000 ;4000 bytes
	rep movsw ;Copy screen
	
	;Restore registers
	pop ds
	pop es
	popa
	ret
Save_mainscr endp

;---------------------- Restore screen ------------------------
Restore_mainscr proc
	;Save registers
	pusha
	push es
	push ds
	
	;B900:0000 - first video page
	push 0B900h
	pop ds
	xor si,si
	
	;B800:0000 - zero video page
	push 0B800h
	pop es
	xor di,di
	
	mov cx,2000
	rep movsw
	
	;Restore registers
	pop ds
	pop es
	popa
	ret
Restore_mainscr endp 

;------------------------ Draw frame ---------------------------
;We will draw frame with determined size in the centre of screen
Draw_frame proc
	mov bp,sp
	add bp,2 ;First 2 bytes is offset return from procedure

	push es
	
	
	push 0B800h
	pop es ;In ES segment of zero video page 
	
;__________________________________________
     mov ax,Height_X ;AX = высота нашей рамки
     shr al,1        ;делим высоту на 2 путем смещения битов вправо на 1
     mov dh,11       ;Середина
     sub dh,al       ;DH (строка) ГОТОВА!!!!!

     mov ax,Width_Y  ;AX = ширина нашей рамки
     shr al,1        ;делим ее на 2
     mov dl,39       ;Середина
     sub dl,al       ;DL (колонка) ГОТОВА!!!!!
;Теперь DH содержит центрированный ряд (строку),
;а DL - колонку относительно размеров рамки (окошка)...
;_________________________________________

  ;Сохраним полученный адрес, с которого начинается вывод рамки
  ;Нужно для того, чтобы выводить сообщения в рамке.
     mov Num_DX,dx

     mov ax,Other ;Получим дополнительную информацию
     test al,1    ;Нулевой бит равен 0?
     jz No_copyscr ;Если так, то копировать экран не нужно.

     mov ax,Height_X ;Иначе копируем в область 2 видеостраницы
     add ax,2        ;+2, т.к. учитываем 'г=¬' и 'L=-'
     call Copy_scr

No_copyscr:
     call Get_linear ;получаем линейный адрес в видеобуфере из DX,
     push di         ;который и сохраним...

     mov ax,Attr ;в AH - атрибуты цвета рамки
     mov al,'|'  ;верхний левый угол...
     stosw       ;заносим два байта (атрибут в AH / символ в AL)

     mov al,'='  ;далее...
     mov cx,Width_Y ;в CX - ширина рамки
     rep stosw   ;поехали...

     mov al,'|'  ;завершаем верхний ряд
     stosw

     pop di      ;восстановим DI + 160 (следующий ряд)
     add di,160
     inc dh      ;DH "идет в ногу" с текущим рядом
                 ;нужно для того, чтобы вывести внизу рамки сообщение

;теперь у нас примерно такая ситуация на экране:
;г===========================¬
;_
;где _, там у нас DI и DH


     mov cx,Height_X ;CX - кол-во повторов (высота)

Next_lined:
     push cx ;сохраним счетчик
     push di ;сохраним DI

     mov al,'|' ;вывели этот символ
     stosw

     mov al,32      ;32 - пробел (или 20h или ' ')
     mov cx,Width_Y ;CX = ширина
     rep stosw      ;понеслась...

     mov al,'|' ;завершаем ряд...
     stosw

     pop di
     add di,160 ;переводим DI на следующий ряд
     inc dh     ;передвигаем DH на 1
     pop cx     ;восстановим счетчик
     loop Next_lined ;следующий ряд...

;теперь у нас примерно такая ситуация на экране:
;г===========================¬
;¦                           ¦
;¦                           ¦
;¦                           ¦
;_ - тут DI и DH


     mov al,'|' ;низ рамки...
     stosw

     mov al,'='
     mov cx,Width_Y
     rep stosw

     mov al,'|'
     stosw

;теперь у нас примерно такая ситуация на экране:
;г===========================¬
;¦                           ¦
;¦                           ¦
;¦                           ¦
;L===========================-


;Выводим сообщение внизу рамки
     mov si,Mess_dn   ;SI = адрес строки для вывода
     call Draw_messfr ;Выводим сообщение ВНИЗУ рамки
     ;Вот зачем нам нужно было постоянно увеличивать DH на 1
     ;(чтобы DH "шло в ногу" с DI)!

;теперь у нас примерно такая ситуация на экране:
;г===========================¬
;¦                           ¦
;¦                           ¦
;¦                           ¦
;L==== Сообщение внизу ======-


;Выводим сообщение вверху рамки
     mov dx,Num_DX
     push dx
;Вот нам и адрес верхнего ряда понадобился!
     mov si,Mess_up   ;SI = адрес строки для вывода
     call Draw_messfr ;Выводим сообщение вверху рамки

;теперь у нас примерно такая ситуация на экране:
;г==== Сообщение вверху =====¬
;¦                           ¦
;¦                           ¦
;¦                           ¦
;L==== Сообщение внизу ======-


     pop dx
     add dx,0101h ;First row and first columns 
     mov si,Mess_ins ;Адрес сообщения, которое будет внутри рамки
     or si,si        ;Если там 0, то не выводим...
     jz No_draw
     mov ah,[si] ;Load attribute of symbols
     inc si
     
	 mov cx,Num_rows
Next_str:
	 call Print_string ;Выводим строку...
	 inc dh
	 loop Next_str 
;теперь у нас примерно такая ситуация на экране:
;г==== Сообщение вверху =====¬
;¦Сообщение внутри           ¦
;¦                           ¦
;¦                           ¦
;L==== Сообщение внизу ======-


No_draw:
     pop es ;Restore ES
     ret 16 ;Выходим, очистив стек от переменных в 16 байт (8 слов)	
Draw_frame endp

;----------------------- Вывод сообщениий вверху и внизу рамки --------
Draw_messfr proc
     or si,si ;SI = 0?..
     jz No_drawup ;тогда ничего выводить не надо, выходим

     mov ah,[si]  ;Первый символ строки - атрибут (см. DATA.ASM)
     inc si       ;Следующий байт - начало строки
     call Count_strmid ;Вычисляем середину строки

     call Print_string ;Выводим строку на экран

No_drawup:
     ret
Draw_messfr endp

;----------------------- Преобразование DH:DL в линейный массив -----------
Get_linear proc
    push ax    ;сохраним все используемые регистры
    push bx
    push dx

    shl dl,1   ;математика: умножаем DL на 2 (DL=DL*2)...

    mov al,dh  ;в AL - ряд,
    mov bl,160 ;который нужно умножить на 160
    mul bl     ;умножаем: AL(ряд)*160; результат --- в AX

    mov di,ax ;результат умножения - в DI
    xor dh,dh ;аннулируем DH
    add di,dx ;теперь в DI линейный адрес в видеобуфере.

    pop dx    ;восстанавливаем регистры...
    pop bx
    pop ax
    ret
Get_linear endp

;---------------------- вывод строки на экран ---------------
Print_string proc
     call Get_linear ;Получаем линейный адрес строки

Next_symstr:
     lodsb          ;Получаем очередной символ строки
     or al,al       ;Это 0 (конец строки?)
     jz Stop_outstr ;Да - выходим...
     stosw          ;Иначе заносим в видеобуфер атрибут (AH) и символ (AL)
     jmp short Next_Symstr ;Следующий символ

Stop_outstr:
     ret
Print_string endp

;------------------------- Копирование части экрана ------------
Copy_scr proc
    pusha   ;Как обычно сохраним регистры
    push es
    push ds

    xor dl,dl       ;Обнулим DL на всякий случай. Теперь DH = ряд, DL = 0
    call Get_linear ;Получим линейный адрес

    mov bl,160  ;Получим количество байт, котрые нужно копировать
    mul bl
    mov cx,ax   ;Их - в CX (будем использовать CX как счетчик)

    mov si,di   ;DS:SI - откуда копируем
    xor di,di   ;ES:SI - куда копируем
    mov Num_copySI,si ;Сохраним полученные значения для восстановления
    mov Num_copyDI,di
    mov Num_copyCX,cx
    push 0B800h ;Настроим сегментные регистры
    pop ds
    push 0BA00h
    pop es
    rep movsb  ;Копируем...

    pop ds     ;Восстановим регистры и выйдем...
    pop es
    popa
    ret        ;Теперь есть копия в самом начале 2-ой видеостраницы.

Num_copySI dw ?
Num_copyDI dw ?
Num_copyCX dw ?
Copy_scr endp

; === Восстанавливаем часть экрана ===
;Вход: ничего (все уже сохранено в переменных )
;Выход: ничего
Restore_scr proc
    pusha      ;Сохраним регистры
    push es
    push ds

    mov di,Num_copySI ;Получим сохраненные процедурой Copy_scr значения
    mov si,Num_copyDI
    mov cx,Num_copyCX
    push 0BA00h       ;Настроим сегментные регистры
    pop ds
    push 0B800h
    pop es
    rep movsb  ;Копируем со 2-ой страницы в 0-ую...

    pop ds     ;Восстановим регистры
    pop es
    popa
    ret
Restore_scr endp

;-------------------------- Вычисляем середину строки -------------------------
;Вход: CS:SI - адрес строки
;Выход: DL - середина адреса для вывода строки
Count_strmid proc
     push es ;Сохраним регистры...
     push di
     push ax

     push cs ;ES=CS
     pop es
     mov di,si ;DI=SI
     xor al,al ;AL=0
     mov cx,0FFFFh ;сколько символов перебирать (возьмем максимум)...
     repne scasb ;Ищем 0 в строке
     ;0 найден! DI указывает на следующий символ за найденным 0

;SI=начало строки
;DI=конец строки+1
     sub di,si ;DI=DI-SI-1 = длина строки
     dec di

     shr di,1  ;Делим длину на 2
     mov ax,40 ;Делим кол-во символов в строке на 2 = 40
     sub ax,di ;AX=40-половина длины строки = нужная колонка
     mov dl,al ;DL=колонка, с которой следует выводить строку!

     pop ax    ;Восстановим регистры
     pop di
     pop es
     ret
Count_strmid endp

;----------------- Clear screen -------------------------------
Clear_screen proc
;Store registers
	push es
	push di
	push ax
	push cx
	
	push 0B800h
	pop es ;In ES segment of zero video page 
	xor di,di
	mov ax,Main_color
	mov al,20h
	mov cx,25
	
Next_line:
	push cx
	mov cx,80
	rep stosw
	add di,160
	pop cx
	loop Next_line
	
;Restore registers	
	pop cx
	pop ax
	pop di
	pop es
	
	ret
Clear_screen endp

;---------------------- Set platforms ------------------------
Set_platforms proc
	pusha
	push es
		
	push 0B800h
	pop es
	mov dx,0121h
	mov Curr_pos,dx ;Store position
	call Get_linear
	mov ax,Main_color
	mov al,0CDh
	mov cx,12
	rep stosw
	
	xor di,di
	
	mov dx,1721h
	call Get_linear
	mov cx,12
	rep stosw
	
	mov ax,Main_color
	mov al,0DBh
	mov dx,1624h
	mov Ball_pos_curr,dx
	mov Ball_pos_pred,dx
	call Get_linear
	mov word ptr es:[di],ax
	
	pop es
	popa
	
	ret
Set_platforms endp

;--------------------- Move left program ----------------------
Move_left_prog proc
	pusha
	
	mov dx,Curr_pos
	cmp dl,1
	je End_move_l

	push es
	dec dl
	mov Curr_pos,dx
	call Get_linear
	mov ax,Main_color
	mov al,0CDh
	push 0B800h
	pop es
	mov word ptr es:[di],ax 
	add di,18h
	mov al,20h
	mov word ptr es:[di],ax
	
	xor di,di
	mov dh,17h
	call Get_linear
	mov al,0CDh
	mov word ptr es:[di],ax 
	add di,18h
	mov al,20h
	mov word ptr es:[di],ax
	
	cmp Start_game,1
	je Game_started_left
	
	mov al,0DBh
	mov dx, Ball_pos_curr
	dec dl
	mov Ball_pos_curr,dx
	mov Ball_pos_pred,dx
	call Get_linear
	mov word ptr es:[di],ax
	mov al,20h
	mov word ptr es:[di+2],ax 
	
Game_started_left:	
	pop es
End_move_l:
   popa
	ret
Move_left_prog endp

;-------------------- Move right program ----------------------
Move_right_prog proc
	pusha
	
	mov dx,Curr_pos
	cmp dl,43h
	je short End_move_r

   push es
	
	inc dl
	mov Curr_pos,dx
	call Get_linear
	mov ax,Main_color
	mov al,20h
	push 0B800h
	pop es
	mov word ptr es:[di-2],ax 
	add di,22
	mov al,0CDh
	mov word ptr es:[di],ax
	
	xor di,di
	mov dh,17h
	call Get_linear
	mov al,20h
	mov word ptr es:[di-2],ax 
	add di,22
	mov al,0CDh
	mov word ptr es:[di],ax
	
	cmp Start_game,1
	je Game_started_right
	
	mov al,0DBh
	mov dx, Ball_pos_curr
	inc dl
	mov Ball_pos_curr,dx
	mov Ball_pos_pred,dx
	call Get_linear
	mov word ptr es:[di],ax
	mov al,20h
	mov word ptr es:[di-2],ax
Game_started_right:
	pop es

End_move_r:
   popa
	ret
Move_right_prog endp

;---------------------- Move ball on next position -----------------
;Input: DX - next position of ball
Move_ball proc
	
	push 0B800h
	pop es
	
	mov ax,Main_color
	mov al,0DBh
	
	mov cx,Ball_pos_curr
	mov Ball_pos_pred,cx
	mov Ball_pos_curr,dx
	
	xor di,di
	call Get_linear
	mov word ptr es:[di],ax
	
	mov ax,Main_color
	mov al,20h
	xor di,di
	mov dx,cx
	call Get_linear
	mov word ptr es:[di],ax
	
	ret
Move_ball endp

;--------------------- Display score -------------------------------
;Input: Curr_score - current score
;Output: show current score
Display_score proc
	pusha
	push es
	
	push 0B800h
	pop es
	xor di,di
	mov cx,160
	mov al,3Ah ;Find ':'
	repne scasb
	add di,5 ;Last word of number string
	
	mov dh,byte ptr Game_msg_up
	mov ax,Curr_score
	
;Get digits of score number
	mov bl,Devider
Next_digit:	
	div bl
	;частное в AL
	
	mov dl,ah
	xor ah,ah
	add dl,48 ;здесь остаток в десятичном виде для отображения
	mov word ptr es:[di],dx
	sub di,2 ;предыдущее слово
	
	cmp al,0
	jne Next_digit
	
	pop es
	popa
	ret
	
Devider db 10	
Display_score endp
