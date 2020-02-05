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
			"ss: ", textOutput("ss"),
			# plotOutput("post_proxy")
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output) {
	# Initializing values
	output_log <- reactiveValues(decisions = NULL)  # all judgements
	new_decision <- reactiveValues(decision = NULL) # contains one (last) judgm.
	i <- reactiveValues(i = 1, round1over = FALSE, round2over = FALSE)
	
	# Backend calculations
	output$ss <- renderText({
		if (i$i <= n_init) {
			gen_sim(Xtrain[i$i])
		} else if (i$i <= (n_init + n_update)) {
			i$round1over <- TRUE
			model <- model(Xtrain, as.matrix(output_log$decisions))
			X_acq <- acquire_X(model)
			gen_sim(X_acq)
		} else {
			i$round2over <- TRUE
		}
	})

	# Basic reactions to buttons
	observeEvent(input$realistic, {
		new_decision$decision <- 1
		if (!i$round1over) {
			# Decision log is only populated during round 1
			output_log$decisions <- append(output_log$decisions, 1)
		}
		i$i <- i$i + 1
	})
	observeEvent(input$unrealistic, {
		new_decision$decision <- 0
		if (!i$round1over) {
			# Decision log is only populated during round 1
			output_log$decisions <- append(output_log$decisions, 0)
		}
		i$i <- i$i + 1
	})

	# output$round2 <- renderPrint({
	# 	if (i$stop) {
	# 		X_acq <- acquire_X(Xtrain, as.matrix(output_log$decisions), n_init)
	# 		gen_sim(X_acq)
	# 	}
	# })

	# output$post_proxy <- renderImage({
	# 	if (!i$stop) {
	# 		post_proxy <- 0
	# 	} else {
	# 		post_proxy <- classify(
	# 			Xtrain, as.matrix(output_log$decisions), n_init
	# 		)
	# 	}
	# 	outfile <- tempfile(fileext = '.png')
	# 	png(outfile, width=400, height=400)
	# 	hist(post_proxy)
	# 	dev.off()

	# 	list(src = outfile, alt = "There should be a plot here")
	# }, deleteFile = TRUE)
	output$i <- renderText(i$i)
}

# ================================ Run the app =================================
shinyApp(ui, server)