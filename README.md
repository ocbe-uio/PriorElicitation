[![DOI](https://zenodo.org/badge/235075398.svg)](https://zenodo.org/badge/latestdoi/235075398)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-blue.svg)](https://cran.r-project.org/web/licenses/GPL-3)
[![](https://img.shields.io/github/languages/code-size/ocbe-uio/PriorElicitation.svg)](https://github.com/ocbe-uio/PriorElicitation)
[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![](https://img.shields.io/github/last-commit/ocbe-uio/PriorElicitation.svg)](https://github.com/ocbe-uio/PriorElicitation/commits/release-1.0.0)

# Introduction

This is a web application for collecting data from content "specialists" in order to elicit prior distributions. It is written using [Shiny](https://shiny.rstudio.com/), [R](https://www.r-project.org/) and [Python](https://www.python.org/).

![A screenshot](Screenshot.png)

# Using

## Online version

Please visit the following URL to use the PriorElicitation app on your browser:

https://ocbe.shinyapps.io/elicit/

This online version is currently running on a low-powered server at Shinyapps.io and is prone to instabilities. If you encounter errors while using the software, please use local hosting to run the app from your own computer (next section).

## Local hosting

You can host the app on your computer, which is especially useful for developers. The app also runs noticeably faster locally than it does on the Shinyapps server.

### Dependencies

The Prior Elicitation Shiny app depends on a few R packages to run. You can either visually check the list below or run that command once to make sure you have all the required dependencies installed:

```R
install.packages(c("shiny", "reticulate", "rdrop2", "shinyjs", "scatterplot3d", "shinycssloaders"))
```

## Running the app

Once you have all dependencies installed, run the following command from an interactive R session:

```R
shiny::runGitHub("PriorElicitation", "ocbe-uio", "dev", "Shiny")
```

If you have Make installed, you can also conviently run PriorElicitation from the command line with `make run`.

# Contributing

This is Open Source software and all contributions are welcome. If you would like to report a bug or request a feature, please open an issue on the [Issues page](https://github.com/ocbe-uio/PriorElicitation/issues).

# Citing

This project uses the [Citation File Format (CFF)](https://citation-file-format.github.io/), a human- and machine-readable format in YAML. Please refer to the citation metadata in [CITATION.cff](CITATION.cff). APA- and BibTeX-formatted citations of this software are also available on the "Cite this repository" button at the top of the right panel of [the main repository page](https://github.com/ocbe-uio/PriorElicitation/). Also, please remember to use the Digital Object Identifier shown at the top of this file.
