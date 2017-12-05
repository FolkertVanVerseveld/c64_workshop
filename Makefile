.PHONY: default all clean

default: exercises.pdf hints.pdf
all: answers.pdf exercises.pdf hints.pdf workshop.pdf

images/desk.jpg:
	cd images && $(MAKE) && cd ..
workshop.pdf: images/desk.jpg workshop.tex thanks.tex
	# Run multiple times to get page numbers, bibliography etc. right.
	pdflatex workshop.tex
	pdflatex workshop.tex
exercises.pdf: exercises.tex
	pdflatex exercises.tex
answers.pdf: answers.tex
	pdflatex answers.tex
hints.pdf: hints.tex
	pdflatex hints.tex

clean:
	cd images && $(MAKE) clean && cd ..
	rm -f answers.pdf exercises.pdf hints.pdf workshop.pdf *.aux *.log *.nav *.out *.snm *.toc
