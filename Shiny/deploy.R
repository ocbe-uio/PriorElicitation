# Script to deploy the Shiny app to the web
library(rsconnect)

#Sys.setenv(RETICULATE_PYTHON = "~/.virtualenvs/python_environment/bin/python")

# virtualenv_create(
#     'pyenv', python="~/.virtualenvs/pyenv/bin/python"
# )
# reticulate::use_python("~/.virtualenvs/elicit/bin/python3")

# ==============================================================================
# Removing and recreating a virtual environment
# ==============================================================================
# reticulate::virtualenv_remove("python_environment")
reticulate::virtualenv_create(
    envname = "python_environment",
    python  = "python3"
)

# ==============================================================================
# Purging old pip and explicitly installing a new one
# ==============================================================================
reticulate::virtualenv_remove(
    envname  = "python_environment",
    packages = "pip"
)
reticulate::virtualenv_install(
    envname          = "python_environment",
#     packages = c("pip==19.0.3","numpy","nltk","torch"),
    packages         = c("pip==19.0.3", "numpy", "GPy", "matplotlib"),
    ignore_installed = TRUE
)

# ==============================================================================
# Starting the virtual environment
# ==============================================================================
reticulate::use_virtualenv("python_environment", required = TRUE)
#reticulate::use_python("python")

# ==============================================================================
# Deploying the app
# ==============================================================================
deployApp(
    appDir          = "Shiny/",
    appFileManifest = "Shiny/fileManifest.txt",
    appName         = "elicit",
    appTitle        = "Prior Elicitation",
#    python = "~/.virtualenvs/elicit/bin/python3"
#    python          = "/usr/bin/python"
)
