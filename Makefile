LIVT ?= livt
.DEFAULT_GOAL := test

validate:
	$(LIVT) validate --project .

test:
	$(LIVT) test --project .

build:
	$(LIVT) build --project .

clean:
	$(LIVT) clean --project .

.PHONY: validate test build clean
