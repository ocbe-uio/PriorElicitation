library(reticulate)
library(shiny)
library(rdrop2)

# Manual debugging switch ====================================================

debug <- TRUE

# Starting the virtual environment ===========================================

virtualenv_create(
	envname = "python_environment",
	python  = "python3"
)
virtualenv_remove(envname = "python_environment", packages = "pip")
virtualenv_install(envname = "python_environment", packages = "pip")
virtualenv_install(
	envname          = "python_environment",
	packages         = c(
		"numpy", "GPy", "matplotlib", "IPython",
		"scipy"
	)
)
use_virtualenv("python_environment", required = TRUE)

# Initializing Python and R constants and functions ==========================

source_python("initialObjects.py")
source_python("functions-veri.py")
source_python("functions-pari.py")

# Defining user interface ====================================================

ui <- fluidPage(
	titlePanel("Prior elicitation"),
	sidebarLayout(
		position = "left",
		sidebarPanel(
			conditionalPanel(
				condition = "input.start_veri",
				"Decision", br(),
				actionButton(
					inputId = "realistic",
					label = "Number is realistic",
					style = "background-color:#00BB00"
				),
				actionButton(
					inputId = "unrealistic",
					label = "Number is not realistic",
					style = "background-color:#BB0000"
				)
			),
			conditionalPanel(
				condition = "input.start_pari",
				"Decision", br(),
				actionButton(
					inputId = "choose_left",
					label = "Left plot is more realistic"
				),
				actionButton(
					inputId = "choose_right",
					label = "Right plot is more realistic"
				)
			)
		),
		mainPanel(
			tabsetPanel(type = "tabs",
				tabPanel(
					"Veri-PRECIOUS",
					actionLink("start_veri", "Click here to start"), br(),
					fluidRow(
						column(3, h1("Number: ")),
						column(2, h1(textOutput("ss")))
					),
					fluidRow(
						column(2, h6("Round: ")),
						column(3, h6(textOutput("i")))
					),
					h2(uiOutput("final_link"))
				),
				tabPanel(
					"Pari-Precious",
					actionLink("start_pari", "Click here to start"), br(),
					plotOutput("barplot_left"),
					plotOutput("barplot_right")
				)
			)
		)
	)
)

# Define server logic ========================================================

server <- function(input, output, session) {
	# Initializing reactive values -------------------------------------------
	sim_result <- reactiveValues(series = NULL, latest = NULL)
	decisions <- reactiveValues(series = NULL, latest = NULL)  # judgements (Y)
	X <- reactiveValues(
		permutated = NULL, series = NULL, latest = NULL, grid = NULL,
		plots_heights = list(0, 0)
	) # theta
	model <- reactiveValues(fit = NULL)
	proxy <- reactiveValues(lik = 0, post = 0, pred_f = NULL)
	i <- reactiveValues(i = 0, round1over = FALSE, round2over = FALSE)

	# Starting Veri or Pari-PRECIOUS -----------------------------------------
	observeEvent(input$start_veri, {
		init_x_values <- init_X("veri")
		Xtrain <- init_x_values[[1]]
		X$grid  <- init_x_values[[2]]
		if (i$i == 0) {
			if (debug) {
				# not rearranging X makes debugging easier
				X$permutated <- Xtrain
			} else {
				X$permutated <- sample(Xtrain)
			}
			generate_X_ss()
		}
	})
	observeEvent(input$start_pari, {
		init_x_values <- init_X("pari")
		init_grid_indices      <- init_x_values[[1]]
		anti_init_grid_indices <- init_x_values[[2]]
		Xtrain                 <- init_x_values[[3]]
		X1train                <- init_x_values[[4]]
		X2train                <- init_x_values[[5]]
		X1traingrid            <- init_x_values[[6]]
		X2traingrid            <- init_x_values[[7]]
		Xtrain                 <- init_x_values[[8]]
		if (i$i == 0) {
			if (debug) {
				# not rearranging X makes debugging easier
				X$permutated <- Xtrain
			} else {
				X$permutated <- sample(Xtrain)
			}
			X$plots_heights <- generate_X_plots_heights()
		}
	})

	# Creating function to fit model -----------------------------------------
	fit_model <- reactive({
		if (i$i > n_init) {
			if (i$i == n_init + 1) {
				model_fit(
					as.matrix(X$permutated),
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

	# Creating function to retrieve theta (X) --------------------------------

	get_X <- reactive({
		# Function to retrieve the thetas (Xs) depending on which stage we are
		# Results of this function are one number
		if (i$i <= n_init) {
			# First round
			X$permutated[i$i]
		} else if (i$i <= n_tot) {
			# Second round
			model$fit <- fit_model()
			if (debug) print(model$fit)
			acquire_X(model$fit, X$grid)
		}
	})

	get_X_pairs <- reactive(({
		# Results of this function are pairs of numbers
		if (i$i <= n_init) {
			# First round
			X$permutated[i$i, ]
		} else if (i$i <= n_tot) {
			# Second round
			stop("Under construction")
		}
	}))

	# generating X, simulating value, updating model -------------------------

	generate_X_ss <- reactive({
		i$i <- i$i + 1
		if (i$i <= n_tot) {
			X$latest <- get_X()
			X$series <- append(X$series, X$latest)
			sim_result$latest <- gen_sim(X$latest)
			sim_result$series <- append(sim_result$series, sim_result$latest)
			if (debug) {
				print(X$latest)
				print(sim_result$latest)
			}
		}
	})

	generate_X_plots_heights <- reactive({
		i$i <- i$i + 1
		if (i$i <= n_tot) {
			X$latest <- get_X_pairs()
			gen_X_plots_values(X$latest)  # TODO: Useless Python function? DEL?
			X$plots_heights <- gen_X_plots_values(X$latest)
			if (debug) {
				print(X$latest)
				print(X$plots_heights)
			}
			# browser()#TEMP
			X$series <- append(X$series, X$latest)
		}
	})

	# Recording judgements ---------------------------------------------------
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
	# TODO: add input$choose_left and input$choose_right
	observeEvent(input$choose_left, {
			if (i$i <= n_tot) {
			decisions$latest <- "left"
			decisions$series <- append(decisions$series, "left")
			generate_X_plots_heights()
		}
	})
	observeEvent(input$choose_right, {
			if (i$i <= n_tot) {
			decisions$latest <- "right"
			decisions$series <- append(decisions$series, "right")
			generate_X_plots_heights()
		}
	})

	# Final calculations -----------------------------------------------------

	observe({
		if (i$i > n_tot) {
			# Calculating lik_proxy and post_proxy (after experiment is over)
			proxy$lik <- calc_lik_proxy(model$fit, X$grid)
			proxy$post <- calc_post_proxy(proxy$lik)
			proxy$pred_f <- calc_pred_f(model$fit, X$grid)

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

	# Controls for development -----------------------------------------------

	output$i <- renderText(i$i)
	output$ss <- renderText(sim_result$latest)
	# TODO: randomize order of 1 and 2 below
	output$barplot_left <- renderPlot({
		barplot(
			height = X$plots_heights[[1]],
			names.arg = seq_along(X$plots_heights[[1]])
		)
	})
	output$barplot_right <- renderPlot({
		barplot(
			height = X$plots_heights[[2]],
			names.arg = seq_along(X$plots_heights[[2]])
		)
	})

	# Saving output ----------------------------------------------------------

	session$onSessionEnded(function() {
		saved_objects <- list(
			"gpy_params" = isolate(model$fit$param_array),
			# FIXME: theta_acq and label_acq should match their models counterparts
			# when the model updates are fixed
			"theta_acquisitions" = isolate(X$series), # TODO: must match m.X
			"label_acquisitions" = isolate(decisions$series), # TODO: must match m.Y
			"theta_grid" = isolate(X$grid),
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
			message("Exported list structure:")
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

# Run the app ================================================================

shinyApp(ui, server)
