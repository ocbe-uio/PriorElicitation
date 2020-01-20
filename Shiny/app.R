# TODO: split into ui.R and server.R as soon as app is more standalone
library(shiny)
library(reticulate)

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
			"i: ", textOutput("i"),
			"ss: ", textOutput("ss"),
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output) {
	# Initialize Python and R constants and functions
	source_python("../src/0_Initial_objects.py")
	source_python("../src/functions.py")
	
	output_log <- reactiveValues(decisions = NULL)  # all judgements
	new_decision <- reactiveValues(decision = NULL) # contains one (last) judgm.
	i <- reactiveValues(i = 1)
	
	# Reacting to buttons
	observeEvent(input$realistic, {
		new_decision$decision <- 1
		output_log$decisions <- append(output_log$decisions, 1)
		i$i <- i$i + 1
	})
	observeEvent(input$unrealistic, {
		new_decision$decision <- 0
		output_log$decisions <- append(output_log$decisions, 0)
		i$i <- i$i + 1
	})
	output$ss <- renderText({
		if (i$i <= n_init) {
			gen_sim(Xtrain[i$i])
		} else {
			c(
				"Simulation finalized. Judgement vector:", 
				output_log$decisions
			)
		}
	})

	# Generating other output
	output$i <- renderText(i$i)
	output$decision_log <- renderText(output_log$decisions)
}

# ================================ Run the app =================================
shinyApp(ui, server)