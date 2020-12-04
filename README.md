# Introduction

This is a web application for collecting data from content "specialists" in order to elicit prior distributions. It is written using [Shiny](https://shiny.rstudio.com/), [R](https://www.r-project.org/) and [Python](https://www.python.org/).

![A screenshot](Screenshot.png)

# Using

After the development stage is complete, a stable version of this software will be available online with proper access instructions.

In the meantime, we recommend you try the Shiny application by running the following command from an interactive R session (you may have to run `install.packages("shiny")` before to install the Shiny R package):

```R
shiny::runGitHub("PriorElicitation", "ocbe-uio", "dev", "Shiny")
```

The command above will always run the latest development version of the app available on GitHub. If you download a copy of the code, you can run that local copy by executing the [runShiny.R](runShiny.R) script in R.

```R
source("runShiny.R")
```

# Contributing

This is Open Source software and all contributions are welcome. If you would like to report a bug or request a feature, please open an issue on the [Issues page](https://github.com/ocbe-uio/PriorElicitation/issues).

# Citing

This project uses the [Citation File Format (CFF)](https://citation-file-format.github.io/), a human- and machine-readable format in YAML. Please refer to the citation metadata in [CITATION.cff](CITATION.cff).