#include <stdio.h>
extern unsigned short work__prova_tb__y1__RTI;
// extern char * work__prova_tb__y1__RTISTR;
extern short* y1();

short *xx=0;
void wrapp(void)
{
   // extern int *work__prova_tb__y1;
   // printf("Hello Mondo: %x\n", work__prova_tb__y1__RTI);
   // printf("Hello Mondo: %s\n", work__prova_tb__y1__RTISTR);
   if (xx==0)
      xx=y1();

   if (xx)
     printf("Hello Mondo: %x\n", *xx);
}

