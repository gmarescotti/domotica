TGT=main
TARGETS= $(TGT)_tb

WAVES=$(TGT).vcd

CFLAGS = -fPIC

GHDL=ghdl
OPTS=--workdir=tmp --ieee=synopsys -fexplicit

all: $(WAVES)

i2c_tb : i2c.o i2c_tb.o

main_tb: modules.o uart_menu.o main.o mdio_slave.o mdio.o i2c.o dummy_clocks.o myuart.o main_tb.o

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
	$(GHDL) -r $(OPTS) $< --vcd=$@ --stop-time=10ns

clean:
	@$(RM) *.o *~ $(TARGETS) tmp/* *.vcd testbenches/*~ 
	@ghdl --clean

