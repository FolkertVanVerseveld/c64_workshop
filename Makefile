.PHONY: default all clean

default: exercises_en.pdf exercises.pdf hints.pdf
all: answers.pdf exercises.pdf hints.pdf workshop.pdf workshop_en.pdf

images/desk.jpg:
	cd images && $(MAKE) && cd ..
workshop.pdf: images/desk.jpg workshop.tex thanks.tex
	# Run multiple times to get page numbers, bibliography etc. right.
	pdflatex workshop.tex
	pdflatex workshop.tex
workshop_en.pdf: images/desk.jpg workshop_en.tex thanks.tex
	# Run multiple times to get page numbers, bibliography etc. right.
	pdflatex workshop_en.tex
	pdflatex workshop_en.tex
exercises.pdf: exercises.tex
	pdflatex exercises.tex
exercises_en.pdf: exercises_en.tex
	pdflatex exercises_en.tex
answers.pdf: answers.tex
	pdflatex answers.tex
hints.pdf: hints.tex
	pdflatex hints.tex

clean:
	cd images && $(MAKE) clean && cd ..
	rm -f *.pdf *.aux *.log *.nav *.out *.snm *.toc
