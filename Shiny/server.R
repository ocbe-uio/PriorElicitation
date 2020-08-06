# This script contains the backend (server) operations of the Shiny app

library(reticulate)
library(shiny)
library(rdrop2)

# Starting the virtual environment ===========================================

virtualenv_create(
	envname = "python_environment",
	python  = "python3"
)
virtualenv_install(
	envname = "python_environment",
	packages = c("numpy", "GPy", "matplotlib", "python-dateutil")
)
use_virtualenv("python_environment", required = FALSE)

# Initializing Python and R constants and functions ==========================

source_python("initialObjects.py")
source_python("functions-veri.py")
source_python("functions-pari.py")
if (debug) message("##### Running in debug mode #####")

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
	n <- reactiveValues(init = 0, tot = 0)

	# Starting Veri or Pari-PRECIOUS -----------------------------------------
	observeEvent(input$start_veri, {
		all_n <- init_n(debug, "veri")
		n$init <- all_n[[1]]
		n$tot <- all_n[[2]]
		init_x_values <- init_X("veri", n$init)
		Xtrain <- init_x_values[[1]]
		X$grid <- init_x_values[[2]]
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
		temp_n_init <- init_n(debug, "veri")[[1]]
		init_x_values <- init_X("pari", temp_n_init)
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
				if (length(dim(Xtrain)) == 1) {
					X$permutated <- sample(Xtrain)
				} else {
					X$permutated <- Xtrain[sample(seq_len(nrow(Xtrain))), ]
				}
			}
			generate_X_plots_heights()
		}
		all_n <- init_n(debug, "pari")
		n$init <- as.integer(all_n[[1]])
		n$tot <- as.integer(all_n[[2]])
	})

	# Creating function to fit model -----------------------------------------
	fit_model_veri <- reactive({
		if (i$i > n$init) {
			if (i$i == n$init + 1) {
				model_fit_veri(
					as.matrix(X$permutated),
					as.matrix(decisions$series)
				)
			} else {
				model_update_veri(
					model$fit,
					as.matrix(X$latest),
					as.matrix(decisions$latest),
					i$i, n_opt
				)
			}
		}
	})

	fit_model_pari <- reactive({
		if (i$i > n$init) {
			# Reshaping X and Y ------------------------------------------------
			temp_n_init <- init_n(debug, "veri")[[1]]
			trainfull <- reshapeXY(
				temp_n_init, as.matrix(decisions$series == "left")
			)
			Xtrainfull <- trainfull[[1]]
			Ytrainfull <- trainfull[[2]]
			# Fitting (or refitting) model -------------------------------------
			if (i$i == n$init + 1) {
				model_fit_pari(
					Xtrainfull,
					Ytrainfull
				)
			} else {
				# TODO: develop Python part and adapt
				stop("Remodeling to be implemented") # TEMP
				browser() # TEMP
				model_update_pari(
					model$fit,
					as.matrix(X$latest),
					as.matrix(decisions$latest),
					i$i, n_opt
				)
			}
		}
	})

	# Creating function to retrieve theta (X) --------------------------------

	get_X <- reactive({ # Used by Veri
		# Function to retrieve the thetas (Xs) depending on which stage we are
		# Results of this function are one number
		if (i$i <= n$init) {
			# First round: gather values from pre-generated probability grid
			X$permutated[i$i]
		} else if (i$i <= n$tot) {
			# Second round: gather values from model
			model$fit <- fit_model_veri()
			if (debug) print(model$fit)
			acquire_X_veri(model$fit, X$grid)
		}
	})

	get_X_pairs <- reactive({ # Used by Pari
		# Results of this function are pairs of numbers
		if (i$i <= n$init) {
			# First round: gather values from pre-generated probability grid
			X$permutated[i$i, ]
		} else if (i$i <= n$tot) {
			# Second round: gather values from model
			model$fit <- fit_model_pari()
			if (debug) print(model$fit)
			acquire_X_pari(model$fit, 51L) # ASK: Is n_test fixed? Why?
		}
	})

	# generating X, simulating value, updating model -------------------------

	generate_X_ss <- reactive({ # Used by Veri
		i$i <- i$i + 1
		if (i$i <= n$tot) {
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

	generate_X_plots_heights <- reactive({ # Used by Pari
		i$i <- i$i + 1
		if (i$i <= n$tot) {
			X$latest <- get_X_pairs()
			X$plots_heights <- gen_X_plots_values(as.list(X$latest))
			if (debug) {
				message("Round ", i$i)
				print(X$latest)
				print(X$plots_heights)
			}
			X$series <- append(X$series, X$latest)
		}
	})

	# Recording judgements ---------------------------------------------------
	observeEvent(input$realistic, {
		if (i$i <= n$tot) {
			# Record latest decision
			decisions$latest <- 1
			decisions$series <- append(decisions$series, 1)
			generate_X_ss()
		}
	})
	observeEvent(input$unrealistic, {
		if (i$i <= n$tot) {
			# Record latest decision
			decisions$latest <- 0
			decisions$series <- append(decisions$series, 0)
			generate_X_ss()
		}
	})
	observeEvent(input$choose_left, {
			if (i$i <= n$tot) {
			decisions$latest <- "left"
			decisions$series <- append(decisions$series, "left")
			generate_X_plots_heights()
		}
	})
	observeEvent(input$choose_right, {
			if (i$i <= n$tot) {
			decisions$latest <- "right"
			decisions$series <- append(decisions$series, "right")
			generate_X_plots_heights()
		}
	})

	# Final calculations -----------------------------------------------------

	observe({ # TODO: split veri and pari?
		if (i$i > n$tot) {
			# Calculating lik_proxy and post_proxy (after experiment is over)
			proxy$lik <- calc_lik_proxy_veri(model$fit, X$grid)
			proxy$post <- calc_post_proxy(proxy$lik)
			proxy$pred_f <- calc_pred_f(model$fit, X$grid)

			# Final link
			url <- a("CLICK HERE", href="http://www.uio.no")
			output$final_link <- renderUI({
				if (i$i > n$tot) {
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
	output$barplot_left <- renderPlot({
		barplot(
			height = X$plots_heights[[1]],
			names.arg = seq_along(X$plots_heights[[1]]),
			col = rgb(.2, .3, .5),
			border=NA
		)
	})
	output$barplot_right <- renderPlot({
		barplot(
			height = X$plots_heights[[2]],
			names.arg = seq_along(X$plots_heights[[2]]),
			col = rgb(.2, .3, .5),
			border=NA
		)
	})

	# Saving output ----------------------------------------------------------

	session$onSessionEnded(function() {
		saved_objects <- list(
			"gpy_params" = isolate(model$fit$param_array),
			# FIXME: theta_acq and label_acq should match their models counterparts
			# when the model updates are fixed
			"theta_acquisitions" = isolate(X$series), # TODO must match m.X
			"label_acquisitions" = isolate(decisions$series), # TODO: match m.Y
			"theta_grid"         = isolate(X$grid),
			"lik_proxy"          = isolate(proxy$lik),
			"post_proxy"         = isolate(proxy$post),
			"mean_pred_grid"     = isolate(proxy$pred_f[[1]]),
			"var_pred_grid"      = isolate(proxy$pred_f[[2]]),
			"simulations"        = isolate(sim_result$series)
		)
		machine_name <- system("uname -n", intern=TRUE)
		date_time <- format(Sys.time(), "%Y_%m_%d_%H%M%S")
		file_name <- paste("Results", date_time, machine_name, sep="_")
		if (debug) {
			message("Exported list structure:")
			print(str(saved_objects))
			lapply(saved_objects, summary)
			message("Theta and label acquisitions:")
			print(cbind(
				saved_objects$theta_acquisitions,
				saved_objects$label_acquisitions
			))
		} else {
			saveRDS(saved_objects, file = paste0(file_name, ".rds"))
			drop_upload(paste0(file_name, ".rds"))
			message("Results were exported to the configured Dropbox account")
		}
		stopApp()
	})
}