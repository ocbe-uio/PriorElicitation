library(shiny)
library(reticulate)

# ============== Initialize Python and R constants and functions ===============
source_python("../src/initialObjects.py")
source_python("../src/functions.py")

# Manual debugging switch
debug <- TRUE

# Randomizing X
if (debug) {
	Xtrain_permutated <- Xtrain # not rearranging X makes debugging easier
} else {
	Xtrain_permutated <- sample(Xtrain)
}

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
			"ss: ", textOutput("ss"),
			"post_proxy: ", plotOutput("post_proxy"),
			h2(uiOutput("final_link"))
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output, session) {
	# Initializing values
	decisions <- reactiveValues(series = NULL, latest = NULL)  # judgements (Y)
	model <- reactiveValues(start = NULL, previous = NULL, latest = NULL)
	X <- reactiveValues(series = NULL, latest = NULL)

	sim_result <- reactiveValues(series = NULL, latest = NULL)

	## Misc. counters
	i <- reactiveValues(
		i = 1, round1over = FALSE, round2over = FALSE
	)

	get_X <- reactive({
		# Function to retrieve the thetas (Xs) depending on which stage we are
		if (i$i <= n_init) {
			# First round
			Xtrain_permutated[i$i]
		} else if (i$i <= n_tot) {
			# Second round
			acquire_X(model$previous)
		} else {
			# Experiment over
			0
		}
	})

	# Simulating values for judgement (ss)
	output$ss <- renderText({
		if (i$i <= n_init) {
			# First round
			X$latest <- get_X()
			sim_result$latest <- gen_sim(X$latest)
		} else if (i$i <= n_tot) {
			# Second round
			i$round1over <- TRUE
			if (i$i == n_init + 1) {
				# First turn of second round
				model$start <- model_fit(
					Xtrain = as.matrix(Xtrain_permutated),
					ytrain = as.matrix(decisions$series)
				)
				model$previous <- model$start
				message("Initial model:")
				print(model$previous)
				X$latest <- get_X()
				gen_sim(X$latest)
			} else {
				X$latest <- get_X()
				cat("X = ", X$latest, "\n")
				model$latest <- model_update(
					model$previous, X$latest, as.matrix(decisions$latest), i$i,
					n_opt
				)
				# TODO: update previous model with latest
				if (debug) {
					message(
						"Retrained model given X = ", X$latest,
						" and decision ", decisions$latest, ":"
					)
					print(model$latest)
				}
			}
			sim_result$latest <- gen_sim(X$latest)
		} else {
			i$round2over <- TRUE
		}
	})

	# Basic reactions to buttons (i.e., recording judgements)
	observeEvent(input$realistic, {
		# Record latest decision
		decisions$latest <- 1
		decisions$series <- append(decisions$series, 1)

		if (!i$round1over | !i$round2over) {
			i$i <- i$i + 1
			X$series <- append(X$series, X$latest)
			sim_result$series <- append(sim_result$series, sim_result$latest)
		}
	})
	observeEvent(input$unrealistic, {
		# Record latest decision
		decisions$latest <- 0
		decisions$series <- append(decisions$series, 0)

		if (!i$round1over | !i$round2over) {
			i$i <- i$i + 1
			X$series <- append(X$series, X$latest)
			sim_result$series <- append(sim_result$series, sim_result$latest)
		}
	})

	output$post_proxy <- renderImage({
		if  (!i$round1over | !i$round2over) {
			# Round 1 or round 2 ongoing
			post_proxy <- 0
		} else {
			# Both rounds are over
			post_proxy <- calc_post_proxy(model$latest)
		}
		outfile <- tempfile(fileext = '.png')
		png(outfile, width=400, height=400)
		plot(post_proxy)
		dev.off()

		list(src = outfile, alt = "There should be a plot here")
	}, deleteFile = TRUE)

	url <- a("CLICK HERE", href="http://www.uio.no")
	output$final_link <- renderUI({
		if (i$round1over & i$round2over) {
			tagList(
				"Thank you for your contribution! Please", url,
				"to submit your results and conclude your participation."
			)
		} else {
			NULL
		}
	})

	# Controls for development
	output$i <- renderText(i$i)
	output$r1ovr <- renderText(i$round1over)
	output$r2ovr <- renderText(i$round2over)

	# Saving output
	session$onSessionEnded(function() {
		saved_objects <- list(
			"gpy_params" = isolate(model$latest$param_array),
			# FIXME: theta_acq and label_acq should match their models counterparts
			# when the model updates are fixed
			"theta_acquisitions" = isolate(X$series), # TODO: must match m.X
			"label_acquisitions" = isolate(decisions$series), # TODO: must match m.Y
			"theta_grid" = Xgrid,
			"lik_proxy" = NULL,
			"post_proxy" = isolate(calc_post_proxy(model$latest)),
			"mean_pred_grid" = NULL,
			"var_pred_grid" = NULL,
			"simulations" = isolate(sim_result$series)
		)
		machine_name <- system("uname -n", intern=TRUE)
		date_time <- format(Sys.time(), "%Y_%m_%d_%H%M%S")
		file_name <- paste("Results", machine_name, date_time, sep="_")
		if (debug) {
			cat("Exported list:\n")
			print(lapply(saved_objects, function(x) head(x, 50)))
		} else {
			saveRDS(saved_objects, file = paste0(file_name, ".rds"))
		}
		stopApp()
	})
}

# ================================ Run the app =================================
shinyApp(ui, server)
