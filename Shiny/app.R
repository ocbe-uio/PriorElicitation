# TODO: split into ui.R and server.R as soon as app is more standalone
library(shiny)
library(reticulate)

# ============== Initialize Python and R constants and functions ===============
source_python("../src/functions.py")
source_python("../src/initialObjects.py")

# =========================== Define user interface ============================
ui <- fluidPage(
	titlePanel("Prior elicitation"),
	sidebarLayout(
		position = "right",
		sidebarPanel(
			"Decision",
			br(),
			actionButton(
				inputId = "realistic",
				label = "This is realistic",
				style = "background-color:#00BB00"
			),
			actionButton(
				inputId = "unrealistic",
				label = "This is not realistic", 
				style = "background-color:#BB0000"
			)
		),
		mainPanel(
			"Peeking under the hood for development purposes...", br(),
			"i: ", textOutput("i"),
			"ss: ", textOutput("ss")
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output) {
	# Initializing values
	# TODO: move latest_decision into decisions
	decisions <- reactiveValues(series = NULL, latest = NULL)  # all judgements
	model <- reactiveValues(m = NULL)
	X_acq <- reactiveValues(X = NULL)
	## Misc. counters
	i <- reactiveValues(
		i = 1, round1over = FALSE, round2over = FALSE
	)

	# Train or retrain the model
	# output$model <- renderText({
	# })
	
	# Simulating values for judgement
	output$ss <- renderText({
		if (i$i <= n_init) {
			gen_sim(Xtrain[i$i])
		} else if (i$i <= n_tot) {
			i$round1over <- TRUE
			if (i$i == n_init + 1) {
				# Train the model
				model$m <- model_fit(Xtrain, as.matrix(decisions$series))
			} else if (i$i <= n_tot) {
				# Retrain the model
				model$m <- model_update(
					model$m, X_acq$X, as.matrix(decisions$latest), i$i,
					n_opt
				)
				# model$m <- model_fit(Xtrain, as.matrix(decisions$series))
			}
			X_acq$X <- acquire_X(model$m)
			gen_sim(X_acq$X)
		} else {
			i$round2over <- TRUE
		}
	})

	# Basic reactions to buttons (i.e., recording judgements)
	observeEvent(input$realistic, {
		# Record latest decision
		decisions$latest <- 1
		
		# Append latest decision to the archive
		if (!i$round1over) {
			# Decision log is only populated during round 1
			decisions$series <- append(decisions$series, 1)
		}
		if (!i$round1over | !i$round2over) {
			i$i <- i$i + 1
		}
	})
	observeEvent(input$unrealistic, {
		# Record latest decision
		decisions$latest <- 0

		# Append latest decision to the archive
		if (!i$round1over) {
			# Decision log is only populated during round 1
			decisions$series <- append(decisions$series, 0)
		}
		if (!i$round1over | !i$round2over) {
			i$i <- i$i + 1
		}
	})

	# output$round2 <- renderPrint({
	# 	if (i$stop) {
	# 		X_acq <- acquire_X(Xtrain, as.matrix(decisions$series), n_init)
	# 		gen_sim(X_acq)
	# 	}
	# })

	# output$post_proxy <- renderImage({
	# 	if (!i$stop) {
	# 		post_proxy <- 0
	# 	} else {
	# 		post_proxy <- classify(
	# 			Xtrain, as.matrix(decisions$series), n_init
	# 		)
	# 	}
	# 	outfile <- tempfile(fileext = '.png')
	# 	png(outfile, width=400, height=400)
	# 	hist(post_proxy)
	# 	dev.off()

	# 	list(src = outfile, alt = "There should be a plot here")
	# }, deleteFile = TRUE)

	# Controls for development
	output$i <- renderText(i$i)
	output$r1ovr <- renderText(i$round1over)
	output$r2ovr <- renderText(i$round2over)
}

# ================================ Run the app =================================
shinyApp(ui, server)