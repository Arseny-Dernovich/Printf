%define arg(id) [rbp + 8 + 8 * id]
%define MAX_LEN_BUFFER 256
section .bss

    buffer resb MAX_LEN_BUFFER  
    oct_buffer resb 23       

section .rodata
    
    jump_table:
        dq      default_case                      ; 'a' → .default_case
        dq      parse_binary
        dq      parse_char                        ; 'c' → .parse_char
        dq      parse_int                         ; 'd' → .parse_int
        times   ('o' - 'd' - 1) dq default_case   ; 'e'–'n' → .default_case
        dq      parse_octal                       ; 'o' → .parse_oct
        times   ('s' - 'o' - 1) dq default_case   ; 'p'–'r' → .default_case
        dq      parse_string                      ; 's' → .parse_string
        times   ('x' - 's' - 1) dq default_case   ; 't'–'w' → .default_case
        dq      parse_hex                         ; 'x' → .parse_hex
        times   ('z' - 'x')     dq default_case   ; 'y' и 'z' → .default_case

section .text

    global my_printf, cdecl_print
      

my_printf:

    
    push    r9
    push    r8
    push    rcx
    push    rdx
    push    rsi
    push    rdi        
    
cdecl_print:
    push rbp
    mov rbp , rsp

    mov r8 , 1              ; Счётчик аргументов
    mov rbx , buffer        
    mov rdx , 0             ; Счётчик длины строки

loop:

    mov al , byte [rdi]     ; Читаем текущий символ
    test al , al            ; Проверяем конец строки
    jz Write_Buffer              ; Если 0 (конец) , печатаем буфер

    cmp r8 , 6
    je skip_addr_ret

    cmp al , '%'            ; Проверяем , является ли символ началом формата
    jne store_char        ; Если нет , просто записываем символ

    inc rdi                ; Переходим к символу формата
    mov al , byte [rdi]     ; Читаем символ формата

    
    cmp al , 'a'
    jb default_case       ; Если меньше 'a' , обрабатываем как обычный символ
    cmp al , 'z'
    ja default_case       ; Если больше 'z' , обрабатываем как обычный символ

    
    sub al , 'a'            ; Индекс = al - 'a'
    movzx rax , al          ; Расширяем до 64 бит
    lea rcx , [jump_table]  ; Загружаем адрес таблицы
    jmp [rcx + rax * 8]    ; Переход по адресу из таблицы


;------------------------------------------------
;Write_Buffer - фу-ия вывода буфера на экран
;Describe: rax - номер функции системного вызова
;          rdx - длина выводимого буфера
;          rsi - адрес начала буффера
;Entrance: non
;Destr:    rax , rdx , rbx , rsi , rdi
;-----------------------------------------------
Write_Buffer:
            
    mov     rdi , 1             ; STDOUT (файл 1)
    mov     rsi , buffer        ; Указатель на буфер
    sub     rbx , buffer        ; rbx теперь хранит длину данных

    test    rbx , rbx           ; Если данных нет , просто выйти
    jz      .Write_Buffer_done

.Write_Buffer_loop:
    cmp     rbx , MAX_LEN_BUFFER
    jbe     .write_last_chunk  ; Если меньше лимита — пишем остаток

    mov     rdx , MAX_LEN_BUFFER ; Пишем ровно MAX_LEN_BUFFER байт
    mov     rax  , 0x01     
    syscall                    

    add     rsi , MAX_LEN_BUFFER ; Двигаем указатель буфера
    sub     rbx , MAX_LEN_BUFFER ; Уменьшаем оставшийся размер
    jmp     .Write_Buffer_loop         ; Повторяем цикл

.write_last_chunk:
    mov     rax  , 0x01
    mov     rdx , rbx            ; Пишем оставшиеся байты
    test    rdx , rdx            ; Если 0 байт осталось — не писать
    jz      .Write_Buffer_done
    syscall

.Write_Buffer_done:
    pop     rbp  
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     r8
    pop     r9

    ret

;------------------------------------------------
; store_char - фу-ия записи символа в буфер
; Describe: rbx - указатель на текущую позицию в буфере
;          rdi - указатель на текущую позицию в выводимой строке
;          al  - символ для записи в буфер
; Entrance: rbx - указатель на текущую позицию в буфере
; Destr:    rbx, rdi
;------------------------------------------------
store_char:

    mov     [rbx] , al      
    inc     rbx             
    jmp     next_char

;------------------------------------------------
; parse_char - фу-ия обработки символа
; Describe: r8  - индекс аргумента
;          al  - символ для обработки
; Entrance: r8 - индекс аргумента
; Destr:    r8, rdi, rbx
;------------------------------------------------
parse_char:

    mov     al , arg(r8)         
    inc     r8                  
    jmp     store_char 

;------------------------------------------------
; parse_int - фу-ия обработки целого числа
; Describe: r8  - индекс аргумента
;          esi - переданное целое число
;          rsi - указатель на строку
; Entrance: r8  - индекс аргумента
; Destr:    r8, rdi, rbx, rsi
;------------------------------------------------
parse_int:

  

    mov     esi , arg(r8)        
    movsx   rsi , esi
    inc     r8                  
    call    itoa      
    jmp     next_char        

;------------------------------------------------
; parse_string - фу-ия обработки строки
; Describe: r8  - индекс аргумента
;          rsi - указатель на строку
;          rdi - указатель на буфер
; Entrance: r8  - индекс аргумента
; Destr:    r8, rdi, rbx, rsi
;------------------------------------------------
parse_string:

    inc     rdi

    mov     rsi , arg(r8)    
    inc     r8

.copy_string:

    mov     al , [rsi]
    test    al , al          
    jz      loop
    mov     [rbx] , al       
    inc     rbx
    inc     rsi
    inc     rdx
    jmp     .copy_string

;------------------------------------------------
; parse_binary - фу-ия обработки двоичного числа
; Describe: r8  - индекс аргумента
;          esi - переданное число
;          rdi - указатель на буфер
; Entrance: r8  - индекс аргумента
; Destr:    r8, rdi, rbx, rsi
;------------------------------------------------
parse_binary:

    inc     rdi

    
    mov     esi , arg(r8)        ; Загружаем переданное число
    inc     r8
    call    itob                ; Преобразуем число в двоичную строку
    jmp     loop
    
;------------------------------------------------
; parse_octal - фу-ия обработки восьмеричного числа
; Describe: r8  - индекс аргумента
;          rsi - указатель на строку
;          rdi - указатель на буфер
; Entrance: r8  - индекс аргумента
; Destr:    r8, rdi, rbx, rsi
;------------------------------------------------
parse_octal:

    inc     rdi
    mov     rsi , arg(r8)        ; Загружаем переданное число
    inc     r8
    call    itoo                ; Преобразуем число в восьмеричную строку

    mov     rsi , oct_buffer

.copy_oct:

    mov     al  , [rsi]
    test    al  , al
    jz      loop  
    mov     [rbx] , al
    inc     rbx
    inc     rsi
    inc     rdx 
    jmp     .copy_oct

;------------------------------------------------
; parse_hex - фу-ия обработки шестнадцатеричного числа
; Describe: r8  - индекс аргумента
;          esi - переданное число
;          rdi - указатель на буфер
; Entrance: r8  - индекс аргумента
; Destr:    r8, rdi, rbx, rsi
;------------------------------------------------
parse_hex:

 
    mov     rsi , arg(r8)        
    inc     r8
    call    itox                
    jmp     next_char
    




skip_addr_ret:

    inc r8
    jmp loop

.parse_args:

    mov     al , arg(r8)                       
    inc     r8
    jmp     store_char

next_char:

    inc rdi
    jmp loop

default_case:
    jmp store_char

        

;------------------------------------------------------------------
; itoa - фу-ия преобразования числа в строку в целом представлении
; Describe: результат сразу записывается в buffer
; Entrance: rbx - указатель на буфер для строки
;           rsi - число для преобразования
; Destr:    r8, rsi, rdi, rbx, rcx, rdx
;------------------------------------------------------------------
itoa:

    push    r8
    push    rcx 
    push    rdx
    push    rdi
    push    rsi
                                ; в rbx лежит buffer
        
    mov     rcx , 10             
    mov     r8 , 0              ; Счётчик цифр

    
    test    rsi , rsi            ; Проверяем , отрицательное ли число
    jns     .itoa_non_negative  ; Если положительное , переходим к обычному коду

    mov     byte [rbx] , '-'     
    inc     rbx
    neg     rsi                 

.itoa_non_negative:
    
    test    rsi , rsi            ; Проверяем , не равен ли ноль
    jz      .itoa_zero          ; Если ноль , переходим к обработке нуля

.itoa_loop:

    mov     rax , rsi            
    xor     rdx , rdx            ; Очищаем остаток
    div     rcx                 ; Делим на 10 , результат в rax , остаток в rdx
    add     dl , '0'            
    push    rdx                 
    inc     r8                 
    mov     rsi , rax            
    test    rax , rax            
    jnz     .itoa_loop          

.itoa_pop:

    cmp     r8 , 0              
    je      .itoa_end

    pop     rax                 
    mov     [rbx] , al           
    inc     rbx
    dec     r8                 
    jmp     .itoa_pop           ; Повторяем , пока есть цифры

.itoa_zero:

    mov     byte [rbx] , '0'    
    inc     rbx

.itoa_end:

    mov     byte [rbx] , 0       

    pop     rsi
    pop     rdi
    pop     rdx
    pop     rcx
    pop     r8
    
    ret


;--------------------------------------------------------------------------
; itob - фу-ия преобразования числа в строку с бинарным представлением числа
; Describe: результат сразу записывается в buffer
; Entrance: rbx - указатель на буфер для строки
;           rsi - число для преобразования
; Destr:    r8, rsi, rdi, rbx, rcx, rdx
;----------------------------------------------------------------------------
itob:

    push    rcx
    push    rdx
    push    rdi
    push    rsi


    test    rsi , rsi
    jz      .zero_case       
    
                             ; Находим позицию старшего значащего бита
    mov     rax , rsi
    bsr     rcx , rax         ; rcx = позиция старшего значащего бита (начиная с 0)  

.itob_loop:

    mov     rax , rsi
    shr     rax , cl          ; Сдвигаем текущий бит в младший разряд
    and     rax , 1           ; Изолируем бит
    add     al , '0'          
    mov     [rbx] , al        
    inc     rbx              
    dec     rcx              
    jns     .itob_loop       ; Продолжаем , пока не обработаем все биты
    jmp     .end

.zero_case:

    mov     byte [rbx] , '0'  
    inc     rbx             

.end:

    mov     byte [rbx] , 0    

    pop     rsi
    pop     rdi
    pop     rdx
    pop     rcx

    ret 


;------------------------------------------------------------------------
; itoo - фу-ия преобразования числа в строку в восьмеричном представлении
; Describe: результат  записывается во временный oct_buffer
; Entrance: rbx - указатель на буфер для строки
;           rsi - число для преобразования
; Destr:    r8, rsi, rdi, rbx, rcx, rdx
;------------------------------------------------------------------------
itoo:

    push    rbx                 
    push    rcx
    push    rdx
    push    rdi
    push    rsi

    mov     rdi , oct_buffer     
    mov     rcx , 22             ; Максимальное количество цифр (64 бита / 3)
    xor     rbx , rbx            ; Счетчик цифр

    
    mov     rdx , rsi            ; rdx = исходное число

    ; Сначала определяем длину числа в восьмеричной системе
.calc_length:

    mov     rax , rdx            ; Копируем число в rax
    and     rax , 7              ; Получаем младшие 3 бита (остаток от деления на 8)
    inc     rbx                 ; Увеличиваем счетчик цифр
    shr     rdx , 3              ; Делим число на 8
    test    rdx , rdx            ; Проверяем , осталось ли число
    jnz     .calc_length        ; Если число не 0 , продолжаем

    ; Теперь записываем цифры в буфер в правильном порядке
    mov     rcx , rbx            ; Количество цифр
    lea     rdi , [oct_buffer + rbx] ; Указатель на конец буфера
    mov     byte [rdi] , 0       ; Завершающий нулевой символ
    dec     rdi                 ; Перемещаем указатель на последнюю цифру

    ; Восстанавливаем исходное значение rsi
    mov     rdx , rsi            ; rdx = исходное число

.write_buffer:

    mov     rax , rdx            ; Копируем число в rax
    and     rax , 7              ; Получаем младшие 3 бита (остаток от деления на 8)
    add     al , '0'             ; Преобразуем в ASCII-символ
    mov     [rdi] , al           ; Записываем цифру в буфер
    dec     rdi                 ; Перемещаем указатель назад
    shr     rdx , 3              ; Делим число на 8
    loop    .write_buffer       ; Повторяем , пока все цифры не записаны

    ; Если число было 0 , записываем '0'
    cmp     rbx , 0
    jne     .done
    mov     byte [oct_buffer] , '0'
    mov     byte [oct_buffer + 1] , 0

.done:

    pop     rsi                 ; Восстанавливаем регистры
    pop     rdi
    pop     rdx
    pop     rcx
    pop     rbx
    ret 


;-----------------------------------------------------------------------------
; itox - фу-ия преобразования числа в строку в шестнадцатиричном представлении
; Describe: результат  записывается сразу в buffer
; Entrance: rbx - указатель на буфер для строки
;           rsi - число для преобразования
; Destr:    r8, rsi, rdi, rbx, rcx, rdx
;-----------------------------------------------------------------------------
itox:

    push    rcx
    push    rdx
    push    rdi
    push    rsi

    mov     rdi , rbx           ; Запоминаем начальный адрес буфера

    test    rsi , rsi
    jz      .zero_case         ; Если число равно 0 , обрабатываем отдельно

    mov     rcx , 0             ; Счётчик цифр

.hex_loop:

    mov     rax , rsi
    and     rax , 0xF           ; Берём младшие 4 бита
    cmp     al , 10
    jl      .digit
    add     al , 'A' - 10       ; Преобразуем в A-F
    jmp     .store

.digit:
    add     al , '0'            

.store:

    push    rax                 ; Сохраняем цифру в стек (чтобы записывать в правильном порядке)
    shr     rsi , 4             ; Сдвигаем число на 4 бита вправо
    inc     rcx                
    test    rsi , rsi           
    jnz     .hex_loop

.write_to_buffer:

    pop     rax
    mov     [rbx] , al          
    inc     rbx
    loop    .write_to_buffer   

    jmp     .end

.zero_case:

    mov     byte [rbx] , '0'    
    inc     rbx

.end:

    mov     byte [rbx] , 0      

    pop     rsi
    pop     rdi
    pop     rdx
    pop     rcx

    ret
    