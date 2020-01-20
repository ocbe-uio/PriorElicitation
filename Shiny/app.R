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
			"Xtrain: ", textOutput("test"), #TEMP
			"i: ", textOutput("i"),
			"ss: ", textOutput("ss"),
			"Past judgements: ", textOutput("decision_log")
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output) {
	# Initialize Python and R constants and functions
	source_python("../src/0_Initial_objects.py")
	source_python("../src/functions.py")
	
	output$test <- renderText(Xtrain) #TEMP
	output_log <- reactiveValues(decisions = NULL)  # all judgements
	new_decision <- reactiveValues(decision = NULL) # contains one (last) judgm.
	i <- reactiveValues(i = 1)
	
	# Reacting to buttons
	observeEvent(input$realistic, {
		new_decision$decision <- 1
		output_log$decisions <- append(output_log$decisions, 1)
	})
	observeEvent(input$unrealistic, {
		new_decision$decision <- 0
		output_log$decisions <- append(output_log$decisions, 0)
		i$i <- i$i + 1
	})
	output$ss <- renderText(rbinom(1, 100, Xtrain[i$i]))
	output$i <- renderText(i$i)
	output$decision_log <- renderText(output_log$decisions)
}

# ================================ Run the app =================================
shinyApp(ui, server)