all: main.pdf

main.pdf: main.tex references.bib
	latexmk -pdf -interaction=nonstopmode main.tex

# Rebuild whenever main.tex or references.bib changes. Ctrl-C to stop.
watch:
	latexmk -pdf -pvc -view=none -interaction=nonstopmode main.tex

clean:
	latexmk -C
	rm -f main.bbl main.run.xml

.PHONY: all watch clean
