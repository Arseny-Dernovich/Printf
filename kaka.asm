%define arg(id) [rbp + 8 + 8 * id]
section .bss
    buffer resb 256  
    
section .text
    global my_printf, _start , cdecl_print
    extern main  ; main определён в другом файле (например, на C)

_start:

    call main      ; вызываем main
    mov rdi, 0    ; код возврата 0
    mov rax, 60   ; syscall: exit
    syscall       ; завершаем программу

my_printf:

    ; Пушим все необходимые регистры с аргументами
    push    r9
    push    r8
    push    rcx
    push    rdx
    push    rsi
    push    rdi        
    
cdecl_print:

    push    rbp                 ; Сохраняем старое значение rbp
    mov     rbp, rsp            ; Устанавливаем новый rbp

    mov     r8 , 1                 ; счётчик аругментов

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

    cmp     r8 , 6
    je      .skip_addr_ret
    jmp     .parse_args

.store_char:
    mov     [rbx], al       ; Кладём символ в буфер
    inc     rbx             ; Увеличиваем указатель буфера
    inc     rdi             ; Переходим к следующему символу
    inc     rdx             ; Увеличиваем счётчик длины
    jmp     .loop


.skip_addr_ret:

    inc r8
    jmp .parse_args

.parse_args:


    mov     al, arg(r8)                       ; Загружаем переданный символ
    inc     r8
    jmp     .store_char

.flush:
    mov     rax, 0x01       ; syscall write
    mov     rdi, 1          ; stdout
    mov     rsi, buffer     ; Адрес буфера
    syscall                 ; Вызываем системный вызов

            ; pop     rsi
            ; pop     rdi
            
    pop     rbp  
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     r8
    pop     r9

    ret
        
            