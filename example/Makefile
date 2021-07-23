ELM_SRC=$(wildcard src/*.elm)
JS=$(patsubst src/%.elm,bin/%.js,$(ELM_SRC))


all: bin $(JS)

bin/%.js: src/%.elm
	../bin/elm-cli make $< $@

bin:
	mkdir bin

run: all
	@$(foreach js,$(JS),echo ---$(js);$(js);echo "";)

clean:
	rm bin/*

