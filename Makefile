.PHONY: default clean

default: workshop.pdf
workshop.pdf: workshop.tex thanks.tex
	pdflatex workshop.tex

clean:
	rm -f workshop.pdf *.aux *.log *.nav *.out *.snm *.toc
