# https://robjhyndman.com/hyndsight/makefiles/

# README

# REQUIRES: reveal-md
#	- "make all" to build files
#	- "make post" to copy public files to GitHub

path = Users/bcooley/Dropbox\ \(Princeton\)/8_Templates/
# RDIR = ./estimation
# RFILES := $(wildcard $(RDIR)/*.R)
# OUT_FILES := $(RFILES:.R=.Rout)

github = ~/GitHub/epbt
website_docs = ~/Dropbox\ \(Princeton\)/5_CV/website/static/docs
# github_slides = ~/GitHub/epbt_slides
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
	cp -a Makefile $(github);
	# slides
	mkdir -p $(github)/index_files/;
	cp -a index_files/ $(github)/index_files/;
	mkdir -p $(github)/figure/;
	cp -a figure/ $(github)/figure/;
	cp -a cooley-reveal.html $(github);
	cp -a plugins.html $(github);
	mkdir -p $(github)/css/;
	cp -a css/ $(github)/css/;
	cp -a epbt_slides.Rmd index.html $(github);
# 	cp -a epbt_slides.pdf $(github);
# 	cp -a epbt_handout.pdf $(github);
	# post to website
	cp -a epbt.pdf $(website_docs);
# 	cp -a epbt_handout.pdf $(website_docs)


all: epbt.md epbt.pdf index.html
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

# epbt_slides: epbt_slides.rmd
# 	Rscript -e "rmarkdown::render('epbt_slides.rmd')"

# epbt_slides.html: epbt_slides.md
# 	reveal-md epbt_slides.md --static epbt_slides

index.html: epbt_slides.Rmd
	R --slave -e "rmarkdown::render('epbt_slides.Rmd',output_file='index.html')"

# epbt_slides.md: epbt_slides.Rmd
# 	R --slave -e "set.seed(100);knitr::knit('$<')"

# epbt_slides.pdf: epbt_slides.md
# 	pandoc -t beamer --template=/$(path)$/cooley-latex-beamer.tex --slide-level 2 \
# 	--filter pandoc-citeproc \
# 	epbt_slides.md -o epbt_slides.pdf

# epbt_handout.pdf: epbt_slides.md
# 	pandoc -t beamer --template=/$(path)$/cooley-latex-beamer-handout.tex --slide-level 2 \
# 	--filter pandoc-citeproc \
# 	epbt_slides.md -o epbt_handout.pdf

clean:
	rm -fv $(OUT_FILES) 

.PHONY: all clean post