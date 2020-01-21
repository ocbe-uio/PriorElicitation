# TODO: split into ui.R and server.R as soon as app is more standalone
library(shiny)
library(reticulate)

# ============== Initialize Python and R constants and functions ===============
source_python("../src/GPy_logit_link.py")
source_python("../src/0_Initial_objects.py")

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
			"post_proxy: ",
			br(),
			plotOutput("post_proxy")
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output) {
	# Initializing values
	output_log <- reactiveValues(decisions = NULL)  # all judgements
	new_decision <- reactiveValues(decision = NULL) # contains one (last) judgm.
	i <- reactiveValues(i = 1, stop = FALSE)
	
	# Backend calculations
	output$ss <- renderText({
		if (i$i <= n_init) {
			gen_sim(Xtrain[i$i])
		} else {
			c(
				"Simulation finalized. Judgement vector:", 
				output_log$decisions
			)
			i$stop <- TRUE
		}
	})

	# Basic reactions to buttons
	observeEvent(input$realistic, {
		new_decision$decision <- 1
		if (!i$stop) {
			output_log$decisions <- append(output_log$decisions, 1)
			i$i <- i$i + 1
		}
	})
	observeEvent(input$unrealistic, {
		new_decision$decision <- 0
		if (!i$stop) {
			output_log$decisions <- append(output_log$decisions, 0)
			i$i <- i$i + 1
		}
	})

	output$post_proxy <- renderImage({
		if (!i$stop) {
			post_proxy <- 0
		} else {
			post_proxy <- classify(
				Xtrain, as.matrix(output_log$decisions), n_init
			)
		}
		outfile <- tempfile(fileext = '.png')
		png(outfile, width=400, height=400)
		hist(post_proxy)
		dev.off()

		list(src = outfile, alt = "There should be a plot here")
	}, deleteFile = TRUE)
	output$i <- renderText(i$i)
}

# ================================ Run the app =================================
shinyApp(ui, server)