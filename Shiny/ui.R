# This script contains the frontend (user) interface of the shiny app.
library(shinycssloaders)
library(shinyjs)

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
			conditionalPanel(
				condition = "input.start_pari",
				"Decision", br(),
				"(please wait for the plots to update", br(),
				"before clicking the buttons below)", br(),
				shinyjs::disable(
					actionButton(
						inputId = "choose_left",
						label = "Left/top plot is more realistic"
					),
				),
				shinyjs::disable(
					actionButton(
						inputId = "choose_right",
						label = "Right/bottom plot is more realistic"
					)
				)
			)
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
					withSpinner(plotOutput("barplot_left")),
					withSpinner(plotOutput("barplot_right"))
				)
			)
		)
	)
)
