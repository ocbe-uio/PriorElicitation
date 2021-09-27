run:
	R -e 'shiny::runApp("Shiny", launch.browser=TRUE, port=7519)'
rerun:
	R -e 'shiny::runApp("Shiny", launch.browser=FALSE, port=7519)'
runRandPort:
	R -e 'shiny::runApp("Shiny", launch.browser=TRUE)'
deploy:
	R -e 'rsconnect::deployApp(appDir="Shiny/", appName="elicit", appTitle="Prior Elicitation", forceUpdate=TRUE)'
clean:
	trash Shiny/Results_*
	trash Results_*
incrementbuildversion:
	increment_cff_build_version.sh
