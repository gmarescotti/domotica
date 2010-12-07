#include <stdlib.h>

#include <termios.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/signal.h>
#include <sys/types.h>

#define MODEMDEVICE "/dev/ttyUSB0"
#define FALSE 0
#define TRUE 1

volatile int STOP=FALSE;

void signal_handler_IO (int status);    //definition of signal handler
int wait_flag=TRUE;                     //TRUE while no signal received
long BAUD = B57600;         // default Baud Rate (110 through 38400)
long DATABITS = CS8;
long STOPBITS = 0; // 1bit stop (per 2 -> CSTOPB)
long PARITYON = 0;
long PARITY = 0;
                  // 00 = NONE, 01 = Odd, 02 = Even, 03 = Mark, 04 = Space

main(int argc, char *argv[])
{
   char Param_strings[7][80];
   char message[90];

   int fd, res, i;
   char In1, Key;
   struct termios oldtio, newtio;       //place for old and new port settings for serial port
   struct termios oldkey, newkey;       //place tor old and new port settings for keyboard teletype
   struct sigaction saio;               //definition of signal action
   char buf[255];                       //buffer for where data is put
   int status;
   
   //open the device(com port) to be non-blocking (read will return immediately)
   fd = open(MODEMDEVICE, O_RDWR | O_NOCTTY | O_NONBLOCK);
   if (fd < 0) {
      perror(MODEMDEVICE);
      exit(-1);
   }

   // int flags = fcntl(0, F_GETFL, 0);
   // fcntl(0, F_SETFL, flags|O_NONBLOCK|O_NOCTTY);
   // tty = open("/dev/tty", O_RDWR | O_NOCTTY | O_NONBLOCK); //set the user console port up

   int tty=0;
   tcgetattr(tty,&oldkey); // save current port settings   //so commands are interpreted right for this program
   // set new port settings for non-canonical input processing  //must be NOCTTY
   newkey = oldkey;
   // newkey.c_cflag = BAUDRATE | CRTSCTS | CS8 | CLOCAL | CREAD;
   newkey.c_cflag = BAUD | CRTSCTS | CS8 | CLOCAL | CREAD;
   newkey.c_iflag = IGNPAR;
   newkey.c_oflag = 0;
   newkey.c_lflag = 0;       //ICANON;
   newkey.c_cc[VMIN]=1;
   newkey.c_cc[VTIME]=0;
   tcflush(tty, TCIFLUSH);
   tcsetattr(tty,TCSANOW,&newkey);

   //install the serial handler before making the device asynchronous
   saio.sa_handler = signal_handler_IO;
   sigemptyset(&saio.sa_mask);   //saio.sa_mask = 0;
   saio.sa_flags = 0;
   saio.sa_restorer = NULL;
   sigaction(SIGIO,&saio,NULL);

   // allow the process to receive SIGIO
   fcntl(fd, F_SETOWN, getpid());
   // Make the file descriptor asynchronous (the manual page says only
   // O_APPEND and O_NONBLOCK, will work with F_SETFL...)
   fcntl(fd, F_SETFL, FASYNC);

   tcgetattr(fd,&oldtio); // save current port settings 
   // set new port settings for canonical input processing 
   newtio.c_cflag = BAUD | CRTSCTS | DATABITS | STOPBITS | PARITYON | PARITY | CLOCAL | CREAD;
   newtio.c_iflag = IGNPAR;
   newtio.c_oflag = 0;
   newtio.c_lflag = 0;       //ICANON;
   newtio.c_cc[VMIN]=1;
   newtio.c_cc[VTIME]=0;
   tcflush(fd, TCIFLUSH);
   tcsetattr(fd,TCSANOW,&newtio);

   // loop while waiting for input. normally we would do something useful here
   while (STOP==FALSE)
   {
      // fflush(stdin);
      // Key = getchar();

      status = fread(&Key,1,1,stdin);
      if (status==1) { //if a key was hit

	 printf("Hai premuto : %x\n", Key);

	 if (Key == 0x1b) STOP=TRUE;

	 write(fd,&Key,1);          //write 1 byte to the port
      }

      // after receiving SIGIO, wait_flag = FALSE, input is available and can be read
      if (wait_flag==FALSE)  //if input is available
      {
	 res = read(fd,buf,255);

	 if (res>0)
	 {
	    for (i=0; i<res; i++)  //for all chars in string
	    {
	       In1 = buf[i];
	       /*
	       if ((In1<32) || (In1>125))
	       {
		  printf("%d",In1);
	       }
	       else */
	       putchar ((int) In1);
	    }  //end of for all chars in string
	 }  //end if res>0
	 //            buf[res]=0;
	 //            printf(":%s:%d\n", buf, res);
	 //            if (res==1) STOP=TRUE; /* stop loop if only a CR was input */
	 wait_flag = TRUE;      /* wait for new input */
      }  //end if wait flag == FALSE

   }  //while stop==FALSE
   // restore old port settings
   tcsetattr(fd,TCSANOW,&oldtio);
   tcsetattr(tty,TCSANOW,&oldkey);
   close(fd);        //close the com port

   // fcntl(0, F_SETFL, flags & (~O_NONBLOCK));

   printf("Saluti e baci\n");
}  //end of main

/***************************************************************************
* signal handler. sets wait_flag to FALSE, to indicate above loop that     *
* characters have been received.                                           *
***************************************************************************/

void signal_handler_IO (int status)
{
//    printf("received SIGIO signal.\n");
   wait_flag = FALSE;
}

