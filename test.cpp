#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>  
#include "my_printf.h"          

const int ITERATIONS = 1000;

int main ()
{
    double total_my_printf_time = 0.0;
    double total_printf_time = 0.0;

    for (int i = 0 ; i < ITERATIONS ; i++) {
        
        clock_t start_time = clock ();
        my_printf("%d %c %d %c %d %c %o %c %s \n" , -123 , 'x' , 1100 , 'x' , 2200 , 'i' , 511 , 'l' , "hui");                     
        my_printf("%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n" , -1 , "love" , 3802 , 100 , 33 , 30 , -1 , "love" , 3802 , 100 , 33 , 30);
        clock_t end_time = clock ();
        total_my_printf_time += (double)(end_time - start_time) / CLOCKS_PER_SEC;

        
        start_time = clock ();
        printf("%d %c %d %c %d %c %o %c %s \n" , -123 , 'x' , 1100 , 'x' , 2200 , 'i' , 511 , 'l' , "hui");                     
        printf("%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n" , -1 , "love" , 3802 , 100 , 33 , 30 , -1 , "love" , 3802 , 100 , 33 , 30);
        end_time = clock ();
        total_printf_time += (double)(end_time - start_time) / CLOCKS_PER_SEC;
    }

    // Вычисляем среднее время выполнения
    double avg_my_printf_time = total_my_printf_time / ITERATIONS;
    double avg_printf_time = total_printf_time / ITERATIONS;

    printf("Среднее время работы my_printf: %.6f секунд.\n" , avg_my_printf_time);
    printf("Среднее время работы стандартного printf: %.6f секунд.\n" , avg_printf_time);

    return 0;
}
