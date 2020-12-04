# This script contains the frontend (user) interface of the shiny app.
library(shinycssloaders)

ui <- fluidPage(
	shinyjs::useShinyjs(),
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
			"Please select the more realistic plot:",
			conditionalPanel(
				condition = "input.start_pari",
				actionButton(
					inputId = "choose_left",
					label = "Left/top"
				),
				actionButton(
					inputId = "choose_right",
					label = "Right/bottom"
				)
			),
			"(wait until plots are updated to click)"
		),
		mainPanel(
			fluidRow(
				column(1, h6("Round: ")),
				column(1, h6(textOutput("i"))),
				column(1, h6(" of ")),
				column(1, h6(textOutput("ntot")))
			),
			tabsetPanel(
				type = "tabs",
				selected = "Pari-PRECIOUS",
				tabPanel(
					title = "Veri-PRECIOUS",
					actionLink("start_veri", "Click here to start"), br(),
					h2(uiOutput("final_link_veri")),
					fluidRow(
						column(3, h1("Number: ")),
						column(2, h1(textOutput("ss")))
					)
				),
				tabPanel(
					title = "Pari-PRECIOUS",
					actionLink("start_pari", "Click here to start"), br(),
					h2(uiOutput("final_link_pari")),
					shinycssloaders::withSpinner(plotOutput("barplot_left")),
					shinycssloaders::withSpinner(plotOutput("barplot_right"))
				)
			)
		)
	)
)
