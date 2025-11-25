.PHONY: kasumi_regression kasumi_iter_regression kasumi_f8_regression \
	kasumi_f9_regression

all: regression

regression: kasumi_regression kasumi_iter_regression kasumi_f8_regression \
	kasumi_f9_regression

kasumi_regression:
	$(MAKE) -C kasumi regression

kasumi_iter_regression:
	$(MAKE) -C kasumi_iter regression

kasumi_f8_regression:
	$(MAKE) -C kasumi_f8 regression

kasumi_f9_regression:
	$(MAKE) -C kasumi_f9 regression

clean:
	$(MAKE) -C kasumi      clean
	$(MAKE) -C kasumi_iter clean
	$(MAKE) -C kasumi_f8   clean
	$(MAKE) -C kasumi_f9   clean
