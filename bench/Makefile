# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025 Tristan Itschner

all:
	vivado -notrace -nolog -nojournal -mode batch -source ooc.tcl -tclargs $(module)

clean:
	$(RM) *.log
	$(RM) *.jou
	$(RM) clockInfo.txt
	$(RM) *.dcp
