ELM_SRC=$(wildcard src/*_Test.elm)
JS=$(patsubst src/%.elm,bin/%.js,$(ELM_SRC))


all: bin tmp tmp-clean $(JS)

FORCE:
bin/%.js: src/%.elm FORCE
	../bin/elm-cli make $< $@

bin:
	mkdir bin

tmp:
	mkdir tmp


tmp-clean: FORCE
	rm -f tmp/*

run: all
	@$(foreach js,$(JS),echo ---$(js);$(js);echo "";)

clean:
	rm bin/*

