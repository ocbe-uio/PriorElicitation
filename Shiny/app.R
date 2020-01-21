# TODO: split into ui.R and server.R as soon as app is more standalone
library(shiny)
library(reticulate)

# ============== Initialize Python and R constants and functions ===============
source_python("../src/GPy_logit_link.py")
source_python("../src/0_Initial_objects.py")
pred_f <- NA

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
			"stop: ", textOutput("stop"),
			"ss: ", textOutput("ss"),
			"pred_f: ", tableOutput("pred_f")
		)
	)
)

# ============================ Define server logic =============================
server <- function(input, output) {
	output_log <- reactiveValues(decisions = NULL)  # all judgements
	new_decision <- reactiveValues(decision = NULL) # contains one (last) judgm.
	i <- reactiveValues(i = 1, stop = FALSE)
	
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

	output$pred_f <- renderTable({
		if (!i$stop) {
			NA
		} else {
			pred_f <- gen_pred_f(Xtrain, as.matrix(output_log$decisions))
			sapply(pred_f, function(x) head(x, 20))
		}
	})


	# Generating other output
	output$i <- renderText(i$i)
	output$stop <- renderText(i$stop)
}

# ================================ Run the app =================================
shinyApp(ui, server)