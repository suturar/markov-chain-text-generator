run: mct
	./mct
mct: $(wildcard *.odin)
	odin build . -error-pos-style:unix -debug -out:mct
