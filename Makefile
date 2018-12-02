# https://robjhyndman.com/hyndsight/makefiles/

# README

#	- "make all" to build files
#	- "make post" to copy public files to GitHub

path = Users/brendancooley/Dropbox/8_Templates/
# RDIR = ./estimation
# RFILES := $(wildcard $(RDIR)/*.R)
# OUT_FILES := $(RFILES:.R=.Rout)

github = ~/GitHub/epbt
Rscripts = estimation/*.R

post: 
	mkdir -p $(github)/estimation/;
	cp -a $(Rscripts) $(github)/estimation/;
	cp -a epbt.Rmd epbt.md epbt.pdf $(github);
	mkdir -p $(github)/figs;
	cp -a figs $(github);
	mkdir -p $(github)/estimation/figs/;
	cp -a estimation/figs/ $(github)/estimation/figs/;
	mkdir -p $(github)/figure/;
	cp -a figure/ $(github)/figure/;
	cp -a Makefile $(github)



all: epbt.md epbt.pdf epbt_slides.pdf 
	# $(OUT_FILES)

# theta: estimation/1_theta.R 
# 	cd estimation; R --no-save < 1_theta.R

# dists: estimation/2_dists.R 
# 	cd estimation; R --no-save < 2_dists.R

# taus: estimation/3_taus.R
# 	cd estimation; R --no-save < 3_taus.R

# $(RDIR)/%.Rout: $(RDIR)/%.R
# 	cd $(RDIR); R CMD BATCH $(<F)

# R: $(OUT_FILES)

epbt.md: epbt.Rmd
	R --slave -e "set.seed(100);knitr::knit('$<')"

epbt.pdf: epbt.md
	pandoc --template=/$(path)$/cooley-paper-template.latex \
	--filter pandoc-citeproc \
	-o epbt.pdf epbt.md

epbt_slides.pdf: epbt_slides.md
	pandoc -t beamer --template=/$(path)$/cooley-latex-beamer.tex --slide-level 2 \
	--filter pandoc-citeproc \
	epbt_slides.md -o epbt_slides.pdf

clean:
	rm -fv $(OUT_FILES) 

.PHONY: all clean post