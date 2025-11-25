# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025 Tristan Itschner
SRC += kasumi_f9_tb.v

SRC += ../../rtl/kasumi_fi.v
SRC += ../../rtl/kasumi_fl.v
SRC += ../../rtl/kasumi_fo.v
SRC += ../../rtl/kasumi_f.v
SRC += ../../rtl/kasumi_keyschedule.v
SRC += ../../rtl/kasumi_s7.v
SRC += ../../rtl/kasumi_s9.v
SRC += ../../rtl/kasumi_stage.v
SRC += ../../rtl/kasumi_iter.v
SRC += ../../rtl/kasumi_f9.v

IFLAGS += -g2005-sv

VFLAGS += -fst

all: kasumi_f9_tb.ran

%.ran: %.iv
	vvp $< $(VFLAGS)
	touch $@

kasumi_f9_tb.iv: $(SRC)
	iverilog $(IFLAGS) $(SRC) -o $@

define REGRESSION_TEMPLATE = 
REGRESSION_TARGETS += kasumi_f9_tb_t$(1)_tc$(2)_tx$(3)_rx$(4).ran
kasumi_f9_tb_t$(1)_tc$(2)_tx$(3)_rx$(4).iv: $$(SRC)
	iverilog $$(IFLAGS) $$(SRC) \
		-Pkasumi_f9_tb.debug_trace=0 \
		-Pkasumi_f9_tb.testcase=$(1) \
		-Pkasumi_f9_tb.toggle_ctl=$(2) \
		-Pkasumi_f9_tb.toggle_sending=$(3) \
		-Pkasumi_f9_tb.toggle_reception=$(4) \
		-o $$@
endef

TESTCASES   = 1 2 3 4 5
TOGGLES_CTL = 0 1
TOGGLES_TX  = 0 1
TOGGLES_RX  = 0 1

$(foreach testcase,$(TESTCASES), \
	$(foreach toggle_ctl,$(TOGGLES_CTL), \
		$(foreach toggle_tx,$(TOGGLES_TX), \
			$(foreach toggle_rx,$(TOGGLES_RX), \
				$(eval $(call REGRESSION_TEMPLATE,$(testcase),$(toggle_ctl),$(toggle_tx),$(toggle_rx))) \
			) \
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

