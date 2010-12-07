#include <stdio.h>

main() 
{
   char str[100]="none";

   // printf("ciao\n");
   for (;;) {
      scanf("%s", str);
      printf("a.out: %s\n", str);
      fflush(stdout);
      sleep(1);
   }
}

