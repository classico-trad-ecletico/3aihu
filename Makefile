# This Makefile provides sensible defaults for projects
# based on Pandoc and Jekyll, such as:
# - Dockerized runs of Pandoc and Jekyll with separate
#   variables for version numbers = easy update!
# - Lean CSL checkouts without committing to the repo
# - Website built on the gh-pages branch
# - Bibliography path compatible with Jekyll-Scholar

# Global variables and setup {{{1
# ================
VPATH = _lib
vpath %.bib _bibliography
vpath %.yaml . _spec
vpath default.% . _lib
vpath reference.% . _lib
vpath %.scss _sass slides/reveal.js/css/theme/template

DEFAULTS := defaults.yaml references.bib
JEKYLL-VERSION := 4.2.0
PANDOC-VERSION := 2.16.1
JEKYLL/PANDOC  := \
	docker run --rm -v "`pwd`:/srv/jekyll" \
	-h "0.0.0.0:127.0.0.1" -p "4000:4000" \
	palazzo/jekyll-tufte:$(JEKYLL-VERSION)-$(PANDOC-VERSION)
PANDOC/CROSSREF := \
	docker run --rm -v "`pwd`:/data" \
	-u "`id -u`:`id -g`" pandoc/crossref:$(PANDOC-VERSION)
PANDOC/LATEX := \
	docker run --rm -v "`pwd`:/data" \
	-u "`id -u`:`id -g`" palazzo/pandoc-ebgaramond:$(PANDOC-VERSION)

REVEAL  = mixins.scss theme.scss \
					assets/css/revealjs-main.scss

# Targets and recipes {{{1
# ===================
.PHONY : _site
_site : assets/css/main.scss _spec/html.yaml
	@$(JEKYLL/PANDOC) /bin/bash -c \
	"chmod 777 /srv/jekyll && jekyll build --future"

.PHONY : serve
serve : 
	@$(JEKYLL/PANDOC) jekyll serve --future

%.pdf : %.md latex.yaml
	$(PANDOC/LATEX) -d latex -o $@ $<
	@echo "$< > $@"

%.docx : %.md $(DEFAULTS) docx.yaml reference.docx references.bib
	$(PANDOC/CROSSREF) -d _spec/docx -o $@ $<
	@echo "$< > $@"

slides/index.html : _slides/index.md references.bib \
	_revealjs.yaml revealjs-crossref.yaml $(SASS) reveal.js
	@-mkdir -p $(@D)
	@$(PANDOC/CROSSREF) -o $@ -d _revealjs.yaml $<
	@echo $(@D)

$(REVEAL) :
	@test -e reveal.js || \
		git clone --depth=1 https://github.com/hakimel/reveal.js
# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
