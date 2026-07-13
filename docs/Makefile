SPHINXBUILD ?= sphinx-build
SRC          = src
BUILD        = build

.PHONY: html linkcheck clean

html:
	$(SPHINXBUILD) -W --keep-going -b html $(SRC) $(BUILD)/html

linkcheck:
	$(SPHINXBUILD) -W --keep-going -b linkcheck $(SRC) $(BUILD)/linkcheck

clean:
	rm -rf $(BUILD)
