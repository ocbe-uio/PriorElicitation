# Script to deploy the Shiny app to the web
rsconnect::deployApp(
	appDir          = "Shiny/",
	appName         = "elicit",
	appTitle        = "Prior Elicitation",
	forceUpdate     = TRUE
)
