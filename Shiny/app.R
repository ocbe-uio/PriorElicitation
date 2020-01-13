library(shiny)

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
			plotOutput("prior"),
			"Past judgements: ", textOutput("decision_log")
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output) {
	output_log <- reactiveValues(decisions = NULL)
	new_decision <- reactiveValues(decision = NULL, color = NULL)
	observeEvent(input$realistic, {
		new_decision$decision <- "realistic"
		new_decision$data <- rbinom(30, 5, .1)
		output_log$decisions <- append(output_log$decisions, "realistic")
	})
	observeEvent(input$unrealistic, {
		new_decision$decision <- "unrealistic"
		new_decision$data <- rbinom(10, 50, .9)
		output_log$decisions <- append(output_log$decisions, "unrealistic")

	})
	output$prior <- renderPlot({
			if (is.null(new_decision$data)) {
				# Initial prior
				barplot(table(rbinom(100, 10, .5)))
			} else {
				barplot(table(new_decision$data))
			}
	})
	output$decision_log <- renderText(output_log$decisions)
}

# ================================ Run the app =================================
shinyApp(ui, server)