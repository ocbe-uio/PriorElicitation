# Script to deploy the Shiny app to the web
library(rsconnect)
library(reticulate)

# Sys.setenv(RETICULATE_PYTHON = "~/.virtualenvs/pyenv/bin/python")

# virtualenv_create(
#     'pyenv', python="~/.virtualenvs/pyenv/bin/python"
# )
# use_python("~/.virtualenvs/pyenv/bin/python")

deployApp(
    appDir = "Shiny/",
    appFileManifest = "Shiny/fileManifest.txt",
    appName = "elicit",
    appTitle = "Prior Elicitation",
    python = "~/.virtualenvs/pyenv/bin/python"
)