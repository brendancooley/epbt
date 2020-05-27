import os
import sys
import glob
from doit import get_var

config = {"EUD": get_var('EUD', 'False'), "tpsp": get_var('tpsp', 'False'),
"size": get_var('size', 'all/')}

helpersPath = os.path.expanduser("~/Dropbox (Princeton)/14_Software/R/")
sys.path.insert(1, helpersPath)

# estimation directory
estdir = "01_code/"
shinydir = "04_viz/"
figsdir = "03_figs/"

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
results = "12_results.R"

templatesPath = "~/Dropbox\ \(Princeton\)/8_Templates/"
softwarePath = "~/Dropbox\ \(Princeton\)/14_Software/"
github = "~/GitHub/epbt"
website_docs = "~/Dropbox\ \(Princeton\)/5_CV/website/static/docs"
website_docs_github = "~/Github/brendancooley.github.io/docs"
tpspDataPath = "~/Dropbox\ \(Princeton\)/1_Papers/tpsp/01_data/data/"
dataPath = "~/Dropbox\ \(Princeton\)/1_Papers/epbt/01_data/"

verticatorPath = "~/Dropbox\ \(Princeton\)/8_Templates/plugin/verticator"
pluginDest = "index_files/reveal.js-3.8.0/plugin"
revealPath = "~/Dropbox\ \(Princeton\)/8_Templates/reveal.js-3.8.0"

M = 100  # number of bootstrap iterations

def task_source():
	yield {
		'name': "initializing environment...",
		'actions':["mkdir -p templates/",
				   "cp " + templatesPath + "cooley-paper-template.latex" + " templates/",
				   "cp -a " + softwarePath + " source/"]
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
		'actions': ['cd ' + estdir + '; Rscript ' + accounts + ' %(EUD)s False False',
					'cd ' + estdir + '; Rscript ' + flowshs6,
					'cd ' + estdir + '; Rscript ' + flowshs2 + ' %(EUD)s False False',
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

	To run:
	doit results:results --EUD False
	doit results:results --EUD True

	"""
	yield {
		'name': "results",
		'params': [{'name':'EUD',
					'long':'EUD',
					'type':str,
					'default':'False'}],
		'actions': ['cd ' + estdir + '; Rscript ' + prices + ' %(EUD)s False all/ False 1',
					'cd ' + estdir + '; Rscript ' + freight + ' %(EUD)s False all/ False 1',
					'cd ' + estdir + '; Rscript ' + tau + ' %(EUD)s False all/ False 1',
					'cd ' + estdir + '; Rscript ' + correlates],
		'verbosity': 2,
	}

def task_bootstrap():
	"""
	To run:
	doit EUD=False tpsp=False size=all/ bootstrap
	"""
	for i in range(1, M+1):
		yield {
		'name': "bootstrap iteration " + str(i) + "...",
		'actions': ['cd ' + estdir + '; Rscript ' + prices + " " + config["EUD"] + " " + 
					config["tpsp"] + " " + config["size"] + ' True ' + str(i), 
					'cd ' + estdir + '; Rscript ' + freight + " " + config["EUD"] +  " " + 
					config["tpsp"] + " " + config["size"] + ' True ' + str(i),
					'cd ' + estdir + '; Rscript ' + tau + " " + config["EUD"] +  " " + 
					config["tpsp"] + " " + config["size"] + ' True ' + str(i)],
		'verbosity': 2,
	}
	yield {
		'name': "summarizing...",
		'actions': ['cd ' + estdir + "; Rscript " + results + " " + config["EUD"] + " " + 
					config["tpsp"] + " " + config["size"]]
	}
	if config["tpsp"] == "True":
		for i in range(1, M+1):
			yield {
				'name': "transferring  " + str(i) + "...",
				'actions':['cd ' + estdir + '; Rscript tpsp.R True ' + config["size"] + ' True ' + str(i),
						   "mkdir -p " + tpspDataPath + config["size"] + str(i) + "/",
						   "cp -a " + dataPath + "tpsp_bootstrap_" + config["size"] + str(i) + "/ " + tpspDataPath + config["size"] + "/" + str(i) + "/"]
			}


def task_tpsp():
	"""Export modular economies for companion paper, "Trade Policy in the Shadow of Power." Takes command line argument --mini and exports smaller subset of countries to
	separate folder if True (see lists in params.R).
	
	To execute run  
	doit tpsp:tpsp --size mini/
	options: mini/ mid/ large/


	"""

	# TODO: run tpsp.R and export stuff

	yield {
		'name': 'tpsp',
		'params':[{'name':'size',
		      'long':'size',
		      'type':str,
		      'default':'mini/'}],
		'actions': ['cd ' + estdir + '; Rscript ' + accounts + ' False True %(size)s',
					'cd ' + estdir + '; Rscript ' + flowshs2 + ' False True %(size)s',
					'cd ' + estdir + '; Rscript ' + prices + ' False True %(size)s False 1',
					'cd ' + estdir + '; Rscript ' + freight + ' False True %(size)s False 1',
					'cd ' + estdir + '; Rscript ' + tau + ' False True %(size)s False 1',
					'cd ' + estdir + '; Rscript tpsp.R True %(size)s False 0',
					"mkdir -p " + tpspDataPath + "%(size)s",
					"cp -a " + dataPath + "tpsp_data_" + "%(size)s " + tpspDataPath + "%(size)s"],
		'verbosity': 2,
	}

def task_paper():
	"""

	"""
	if os.path.isfile("references.RData") is False:
		yield {
			'name': "collecting references...",
			'actions':["R --slave -e \"set.seed(100);knitr::knit('epbt.rmd')\""]
        }
	yield {
    	'name': "writing paper...",
    	'actions':["R --slave -e \"set.seed(100);knitr::knit('epbt.rmd')\"",
                   "pandoc --template=templates/cooley-paper-template.latex --filter pandoc-citeproc -o epbt.pdf epbt.md"],
                   'verbosity': 2,
	}

def task_post_to_web():
	"""

	"""
	yield {
		'name': "posting...",
		'actions': ["cp -a epbt.pdf " + website_docs,
					"cp -a epbt.pdf " + website_docs_github]
	}

def task_prep_slides():
	"""

	"""
	yield {
		'name': "moving slide files",
		'actions': ["mkdir -p css",
					"cp -a " + templatesPath + "slides/ " + "css/"]
	}

def task_slides():
	"""

	"""
	yield {
		'name': 'draft slides',
		'actions': ["R --slave -e \"rmarkdown::render('epbt_slides.Rmd', output_file='index.html')\"",
            "perl -pi -w -e 's{reveal.js-3.3.0.1}{reveal.js-3.8.0}g' index.html",
            "cp -r " + revealPath + " index_files/",
            "cp -a " + verticatorPath + " " + pluginDest],
		'verbosity': 2,
	}

def task_prep_shiny():
	"""

	"""
	yield {
		'name': "moving params...",
		'actions': ["cp -a " + estdir + "params.R " + shinydir + "params.R",
					"cp -a " + figsdir + "hm.R " + shinydir + "hm.R"]
	}
