FLIST := flist.f
TOP   := tb_top

.PHONY: compile elaborate simulate all gui clean

compile:
	@echo "========================================"
	@echo " Compiling design and testbench"
	@echo "========================================"
	@xvlog -sv -f $(FLIST)

elaborate: compile
	@echo "========================================"
	@echo " Elaborating design"
	@echo "========================================"
	@xelab $(TOP) -s $(TOP)_sim

simulate: elaborate
	@echo "========================================"
	@echo " Running simulation"
	@echo "========================================"
	@xsim $(TOP)_sim -runall

all: simulate

gui:
	@echo "========================================"
	@echo " Starting Vivado simulation GUI"
	@echo "========================================"
	@xsim $(TOP)_sim --gui

clean:
	@echo "Cleaning simulation files..."
	@rm -rf xsim.dir .Xil
	@rm -f *.jou *.log *.pb *.wdb
