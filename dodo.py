import os
import sys
import glob

helpersPath = os.path.expanduser("~/Dropbox (Princeton)/14_Software/R/")
sys.path.insert(1, helpersPath)

# estimation directory
estdir = "01_analysis/"

accounts = "01_accounts.R"
flowshs6 = "02_flowshs6.R"
flowshs2 = "03_flowshs2.R"
prices = "04_prices.R"
freight = "05_freight.R"
tau = "06_tau.R"
ntm = "07_ntm.R"
tar = "08_tar.R"
pta = "09_pta.R"
polity = "10_polity.R"
correlates = "11_correlates.R"

templatePath = "~/Dropbox\ \(Princeton\)/8_Templates/"
softwarePath = "~/Dropbox\ \(Princeton\)/14_Software/"
github = "~/GitHub/epbt"
website_docs = "~/Dropbox\ \(Princeton\)/5_CV/website/static/docs"
Rscripts = "estimation/*.R"
tpspPath = "~/Dropbox\ \(Princeton\)/1_Papers/tpsp/working/analysis/"

def task_source():
	yield {
		'name': "initializing environment...",
		'actions':["cp -a " + softwarePath + "R/ " + estdir + "source/"]
	}

def task_extract():
	"""Get non-proprietary data from sources, execute estdir/00_extract.R

	"""
	yield {
		'name': "extract data",
		'actions': ['cd ' + estdir + '; Rscript 00_extract.R'],
	}

def task_cleanclean():
	"""Clean data, export to cleandir (see params.R). Task takes command line argument
		--EUD: True or False
			disaggregates European Union countries if True

	NOTE: needs to be run twice to replicate paper...first with EUD False and next with EUD True

	To execute, run doit cleanclean:cd --EUD True
	"""

	yield {
		'name': "cd",
		'params': [{'name':'EUD',
					'long':'EUD',
					'short': 'e',
					'type':str,
					'default':'False'}],
		'actions': ['cd ' + estdir + '; Rscript ' + accounts + ' %(EUD)s False',
					'cd ' + estdir + '; Rscript ' + flowshs6,
					'cd ' + estdir + '; Rscript ' + flowshs2 + ' %(EUD)s False',
					'cd ' + estdir + '; Rscript ' + ntm,
					'cd ' + estdir + '; Rscript ' + tar,
					'cd ' + estdir + '; Rscript ' + pta,
					'cd ' + estdir + '; Rscript ' + polity],
		'verbosity': 2,
	}

def task_results():
	"""Compile results, export to resultsdir (see params.R) Task takes command line argument
		--EUD: True or False
			disaggregates European Union countries if True

	NOTE: needs to be run twice to replicate paper...first with EUD False and next with EUD True
	NOTE: prices and tau need to be run together whenever theta/sigma are updated
	"""
	yield {
		'name': "results",
		'params': [{'name':'EUD',
					'long':'EUD',
					'type':str,
					'default':'False'}],
		'actions': ['cd ' + estdir + '; Rscript ' + prices + ' %(EUD)s False',
					'cd ' + estdir + '; Rscript ' + freight + ' %(EUD)s False',
					'cd ' + estdir + '; Rscript ' + tau + ' %(EUD)s False',
					'cd ' + estdir + '; Rscript ' + correlates],
		'verbosity': 2,
	}

def task_tpsp():
	"""Export modular economies for companion paper, "Trade Policy in the Shadow of Power"

	"""

	# TODO: run tpsp.R and export stuff

	yield {
		'name': 'export tpsp economy',
		'actions': ['cd ' + estdir + '; Rscript ' + accounts + ' False True',
					'cd ' + estdir + '; Rscript ' + flowshs2 + ' False True',
					'cd ' + estdir + '; Rscript ' + prices + ' False True',
					'cd ' + estdir + '; Rscript ' + freight + ' False True',
					'cd ' + estdir + '; Rscript ' + tau + ' False True',
					'cd ' + estdir + '; Rscript tpsp.R',
					"mkdir -p " + tpspPath + "tpsp_data/",
					"cp -a " + estdir + "tpsp_data/ " + tpspPath + "tpsp_data/"],
		'verbosity': 2,
	}

def task_paper():
	"""

	"""
	yield {
		'name': "draft paper",
		'actions': ["R --slave -e \"set.seed(100); knitr::knit('epbt.rmd')\"",
					"pandoc --template=/" + templatePath + "/cooley-paper-template.latex \
					--filter pandoc-citeproc \
					-o epbt.pdf epbt.md"],
		'verbosity': 2,
	}

def task_prep_slides():
	"""

	"""
	yield {
		'name': "moving slide files",
		'actions': ["mkdir -p css",
					"cp -a " + templatePath + "slides/ " + "css/"]
	}

def task_slides():
	"""

	"""
	yield {
		'name': 'draft slides',
		'actions': ["R --slave -e \"rmarkdown::render('epbt_slides.Rmd', output_file='index.html')\""],
		'verbosity': 2,
	}

def task_post():
	"""
	"""

	yield {
		'name': 'post materials to Github/website',
		'actions': ["mkdir -p " + github + "/estimation/",
					"cp -a epbt.Rmd epbt.md epbt.pdf " + github,
					"mkdir -p " + github + "/figs",
					"cp -a figs " + github,
					"mkdir -p " + github + "/estimation/figs/",
					"mkdir -p " + github + "/figure/",
					"cp -a figure/ " + github + "/figure/",
					"cp -a dodo.py " + github,
					"mkdir -p "+ github + "/index_files/",
					"cp -a index_files/ "+ github + "/index_files/",
					"mkdir -p " + github + "/figure/",
					"cp -a figure/ " + github + "/figure/",
					"mkdir -p " + github + "/css/",
					"cp -a css/ " + github + "/css/",
					"cp -a epbt_slides.Rmd index.html " + github,
					"cp -a epbt.pdf " + website_docs],
		'verbosity': 2,
	}
	# move Rscripts
	for rscript in glob.glob(Rscripts):
		yield {
			'name': rscript,
			'actions':["cp -a " + rscript + " " + github + "/estimation/"],
		}
