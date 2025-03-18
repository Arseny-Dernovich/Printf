section .bss
    buffer resb 256  
    
section .text
    global my_printf, _start
    extern main  ; main определён в другом файле (например, на C)

_start:

    call main      ; вызываем main
    mov rdi, 0    ; код возврата 0
    mov rax, 60   ; syscall: exit
    syscall       ; завершаем программу
    
my_printf:
    push    rbp 
    mov     rbp , rsp                                                          
    push    rbx 
    ; push    rdi          
    ; push    rsi          
    
    mov     rbx, buffer  
    mov     rdx, 0       ; Счётчик длины строки

.loop:
    mov     al, byte [rdi]  ; Загружаем текущий символ                      
    test    al, al          ; Проверяем конец строки
    jz      .flush          ; Если 0 (конец), печатаем буфер

    cmp     al, '%'         ; Проверяем '%'
    jne     .store_char

    inc     rdi             
    mov     al, byte [rdi]  ; Загружаем его
    cmp     al, 'c'         ; Проверяем "%c"
    jne     .store_char

    mov     al, sil         ; Загружаем переданный символ
    inc     rsi             ; Смещаемся на следующий аргумент
    jmp     .store_char

.store_char:
    mov     [rbx], al       ; Кладём символ в буфер
    inc     rbx             ; Увеличиваем указатель буфера
    inc     rdi             ; Переходим к следующему символу
    inc     rdx             ; Увеличиваем счётчик длины
    jmp     .loop

.flush:
    mov     rax, 0x01       ; syscall write
    mov     rdi, 1          ; stdout
    mov     rsi, buffer     ; Адрес буфера
    syscall                 ; Вызываем системный вызов

            ; pop     rsi
            ; pop     rdi
    pop     rbx
    pop     rbp             
    ret
        
            