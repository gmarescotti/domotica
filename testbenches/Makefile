TGT=uart
TARGETS= $(TGT)_tb

# TARGETS = pseudo_uart
# adesso: $(TARGETS)

WAVES=$(TGT).vcd

CFLAGS = -fPIC

GHDL=ghdl
OPTS=--workdir=tmp --ieee=synopsys -fexplicit

# tutto: $(TARGETS)

all: $(WAVES)

$(TARGETS): tmp

tmp:
	mkdir tmp

##########################################################
i2c_tb : i2c.o i2c_tb.o

main_tb: ../modules.o main_tb.o ../uart_menu.o ../main.o ../mdio.o mdio_slave.o ../i2c.o dummy_clocks.o ../myuart.o pseudo_uart.o ../display7seg.o

uart_tb: ../modules.o uart_tb.o ../myuart.o

pseudo_uart: ../modules.o ../myuart.o pseudo_uart.o

##########################################################

%.o: %.vhdl
	@echo Adesso creo oggetto $@
	$(GHDL) -a $(OPTS) $<

%.o: %.vhd
	@echo Adesso creo oggetto $@
	$(GHDL) -a $(OPTS) $<

$(TARGETS):
	@echo Adesso creo eseguibile $@
	$(GHDL) -e $(OPTS) $@

%.vcd: %_tb
	@echo Adesso creo diagramma $@ da testbench $<
	@echo digita gtkwave $@, per vedere il diagramma
	$(GHDL) -r $(OPTS) $< --vcd=$@ --assert-level=note
# --stop-time=1ms

clean:
	@$(RM) *.o ../*~ *~ $(TARGETS) tmp/* *.vcd log.txt
	@$(RM) -rf tmp
	@ghdl --clean

