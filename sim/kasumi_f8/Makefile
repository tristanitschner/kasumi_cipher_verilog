# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025 Tristan Itschner
SRC += kasumi_f8_tb.v

SRC += ../../rtl/kasumi_fi.v
SRC += ../../rtl/kasumi_fl.v
SRC += ../../rtl/kasumi_fo.v
SRC += ../../rtl/kasumi_f.v
SRC += ../../rtl/kasumi_keyschedule.v
SRC += ../../rtl/kasumi_s7.v
SRC += ../../rtl/kasumi_s9.v
SRC += ../../rtl/kasumi_stage.v
SRC += ../../rtl/kasumi_iter.v
SRC += ../../rtl/kasumi_f8_ctl.v
SRC += ../../rtl/kasumi_f8.v

IFLAGS += -g2005-sv

VFLAGS += -fst

all: kasumi_f8_tb.ran

%.ran: %.iv
	vvp $< $(VFLAGS)
	touch $@

kasumi_f8_tb.iv: $(SRC)
	iverilog $(IFLAGS) $(SRC) -o $@

define REGRESSION_TEMPLATE = 
REGRESSION_TARGETS += kasumi_f8_tb_t$(1)_tx$(2)_rx$(3).ran
kasumi_f8_tb_t$(1)_tx$(2)_rx$(3).iv: $$(SRC)
	iverilog $$(IFLAGS) $$(SRC) \
		-Pkasumi_f8_tb.debug_trace=0 \
		-Pkasumi_f8_tb.testcase=$(1) \
		-Pkasumi_f8_tb.toggle_sending=$(2) \
		-Pkasumi_f8_tb.toggle_reception=$(3) \
		-o $$@
endef

TESTCASES  = 1 2 3 4 5
TOGGLES_TX = 0 1
TOGGLES_RX = 0 1

$(foreach testcase,$(TESTCASES), \
	$(foreach toggle_tx,$(TOGGLES_TX), \
		$(foreach toggle_rx,$(TOGGLES_RX), \
			$(eval $(call REGRESSION_TEMPLATE,$(testcase),$(toggle_tx),$(toggle_rx))) \
		) \
	) \
)

.PHONY: regression
regression: $(REGRESSION_TARGETS)

.PHONY: list
list:
	@echo $(REGRESSION_TARGETS)

.PHONY: clean
clean:
	$(RM) *.vcd
	$(RM) *.iv
	$(RM) *.ran

