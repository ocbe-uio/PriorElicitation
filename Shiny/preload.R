#Sys.setenv(RETICULATE_PYTHON = "~/.virtualenvs/pyenv/bin/python")

#reticulate::virtualenv_create('pyenv', python="~/.virtualenvs/pyenv/bin/python")
# use_python("~/.virtualenvs/pyenv/bin/python")

rsconnect::deployApp(appFileManifest="fileManifest.txt", appName="elicit")