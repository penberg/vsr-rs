all: main.pdf main.md

main.pdf: main.tex references.bib
	latexmk -pdf -interaction=nonstopmode main.tex

# A Markdown rendering of the paper, for reading on GitHub. Custom
# environments (erratum boxes, interface lemmas, pseudocode) go through md.lua.
main.md: main.tex references.bib md.lua
	pandoc main.tex -f latex+raw_tex -t gfm --lua-filter md.lua \
	  --citeproc --bibliography references.bib --wrap=none -o main.md

# Rebuild whenever main.tex or references.bib changes. Ctrl-C to stop.
watch:
	latexmk -pdf -pvc -view=none -interaction=nonstopmode main.tex

clean:
	latexmk -C
	rm -f main.bbl main.run.xml

.PHONY: all watch clean
