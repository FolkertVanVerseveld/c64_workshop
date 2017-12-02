.PHONY: default clean

default: workshop.pdf

images/desk.jpg:
	cd images && $(MAKE) && cd ..
workshop.pdf: images/desk.jpg workshop.tex thanks.tex
	# Run multiple times to get page numbers, bibliography etc. right.
	pdflatex workshop.tex
	pdflatex workshop.tex

clean:
	cd images && $(MAKE) clean && cd ..
	rm -f workshop.pdf *.aux *.log *.nav *.out *.snm *.toc
