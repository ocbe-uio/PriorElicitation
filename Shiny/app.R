library(reticulate)
library(shiny)
library(rdrop2)
# ==============================================================================
# Starting the virtual environment
# ==============================================================================
virtualenv_create(
	envname = "python_environment",
	python  = "python3"
)
virtualenv_install(
	envname          = "python_environment",
	packages         = c("numpy", "GPy", "matplotlib")
)
use_virtualenv("python_environment", required = TRUE)
# ============== Initialize Python and R constants and functions ===============
source_python("initialObjects.py")
source_python("functions.py")

# Manual debugging switch
debug <- FALSE

# # Randomizing X
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
			actionLink("start", "Click here to start"), br(),
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
	# Initializing reactive values
	sim_result <- reactiveValues(series = NULL, latest = NULL)
	decisions <- reactiveValues(series = NULL, latest = NULL)  # judgements (Y)
	X <- reactiveValues(series = NULL, latest = NULL)  # theta
	model <- reactiveValues(fit = NULL)
	proxy <- reactiveValues(lik = 0, post = 0, pred_f = NULL)
	i <- reactiveValues(i = 0, round1over = FALSE, round2over = FALSE)

	# Creating function to fit model
	fit_model <- reactive({
		if (i$i > n_init) {
			if (i$i == n_init + 1) {
				model_fit(
					as.matrix(Xtrain_permutated),
					as.matrix(decisions$series)
				)
			} else {
				model_update(
					model$fit,
					as.matrix(X$latest),
					as.matrix(decisions$latest),
					i$i, n_opt
				)
			}
		}
	})

	# Creating function to retrieve theta (X)
	get_X <- reactive({
		# Function to retrieve the thetas (Xs) depending on which stage we are
		if (i$i <= n_init) {
			# First round
			Xtrain_permutated[i$i]
		} else if (i$i <= n_tot) {
			# Second round
			model$fit <- fit_model()
			if (debug) print(model$fit)
			acquire_X(model$fit)
		}
	})


	# generating X, simulating value, updating model
	generate_X_ss <- reactive({
		i$i <- i$i + 1
		if (i$i <= n_tot) {
			X$latest <- get_X()
			if (debug) print(X$latest)
			X$series <- append(X$series, X$latest)
			sim_result$latest <- gen_sim(X$latest)
			sim_result$series <- append(sim_result$series, sim_result$latest)
		}
	})

	# Basic reactions to buttons (i.e., starting, recording judgements)
	observeEvent(input$start, {
		if (i$i == 0) generate_X_ss()
	})
	observeEvent(input$realistic, {
		if (i$i <= n_tot) {
			# Record latest decision
			decisions$latest <- 1
			decisions$series <- append(decisions$series, 1)
			generate_X_ss()
		}
	})
	observeEvent(input$unrealistic, {
		if (i$i <= n_tot) {
			# Record latest decision
			decisions$latest <- 0
			decisions$series <- append(decisions$series, 0)
			generate_X_ss()
		}
	})

	# Final calculations
	observe({
		if (i$i > n_tot) {
			# Calculating lik_proxy and post_proxy (after experiment is over)
			proxy$lik <- calc_lik_proxy(model$fit)
			proxy$post <- calc_post_proxy(proxy$lik)
			proxy$pred_f <- calc_pred_f(model$fit)

			# Final plot of post_proxy
			output$post_proxy <- renderImage({
				outfile <- tempfile(fileext = '.png')
				png(outfile, width=400, height=400)
				plot(proxy$post)
				dev.off()

				list(src = outfile, alt = "There should be a plot here")
			}, deleteFile = TRUE)

			# Final link
			url <- a("CLICK HERE", href="http://www.uio.no")
			output$final_link <- renderUI({
				if (i$i > n_tot) {
					tagList(
						"Thank you for your contribution! Please", url,
						"to submit your results",
						"and conclude your participation."
					)
				} else {
					NULL
				}
			})
		}
	})

	# Controls for development
	output$i <- renderText(i$i)
	output$ss <- renderText(sim_result$latest)

	# Saving output
	session$onSessionEnded(function() {
		saved_objects <- list(
			"gpy_params" = isolate(model$fit$param_array),
			# FIXME: theta_acq and label_acq should match their models counterparts
			# when the model updates are fixed
			"theta_acquisitions" = isolate(X$series), # TODO: must match m.X
			"label_acquisitions" = isolate(decisions$series), # TODO: must match m.Y
			"theta_grid" = Xgrid,
			"lik_proxy" = isolate(proxy$lik),
			"post_proxy" = isolate(proxy$post),
			"mean_pred_grid" = isolate(proxy$pred_f[[1]]),
			"var_pred_grid" = isolate(proxy$pred_f[[2]]),
			"simulations" = isolate(sim_result$series)
		)
		machine_name <- system("uname -n", intern=TRUE)
		date_time <- format(Sys.time(), "%Y_%m_%d_%H%M%S")
		file_name <- paste("Results", date_time, machine_name, sep="_")
		if (debug) {
			cat("Exported list structure:\n")
			print(str(saved_objects))
			lapply(saved_objects, summary)
			print(cbind(
				saved_objects$theta_acquisitions,
				saved_objects$label_acquisitions
			))
		} else {
			saveRDS(saved_objects, file = paste0(file_name, ".rds"))
			drop_upload(paste0(file_name, ".rds"))
		}
		stopApp()
	})
}

# ================================ Run the app =================================
shinyApp(ui, server)
