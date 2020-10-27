run:
	R -e 'shiny::runApp("Shiny", launch.browser=TRUE, port=7519)'
rerun:
	R -e 'shiny::runApp("Shiny", launch.browser=FALSE, port=7519)'
deploy:
	R -e 'rsconnect::deployApp(appDir="Shiny/", appName="elicit", appTitle="Prior Elicitation", forceUpdate=TRUE)'