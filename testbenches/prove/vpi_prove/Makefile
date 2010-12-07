CC = /usr/lib/ghdl/bin/gcc
CFLAGS = -fPIC

GHDL=ghdl

all : prova_tb

prova_tb: sniff.o prova_tb.vhdl
	$(GHDL) -a prova_tb.vhdl
	$(GHDL) -e -Wl,sniff.o $@
	$(GHDL) -r prova_tb

sniff.o: sniff.c
	$(CC) -c $(CFLAGS) $<

clean:
	@$(RM) *.o *~ $(TARGETS) tmp/* *.vcd
