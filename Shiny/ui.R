# This script contains the frontend (user) interface of the shiny app.
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
			tabsetPanel(
				type = "tabs",
				selected = "Pari-PRECIOUS",
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
					"Pari-PRECIOUS",
					actionLink("start_pari", "Click here to start"), br(),
					plotOutput("barplot_left"),
					plotOutput("barplot_right")
				)
			)
		)
	)
)
