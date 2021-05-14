# This script contains the frontend (user) interface of the shiny app.
library(shinycssloaders)

ui <- fluidPage(
	shinyjs::useShinyjs(),
	titlePanel("Prior Elicitation"),
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
				"Please select the more realistic plot:", br(),
				actionButton(
					inputId = "choose_left",
					label = "Left/top"
				),
				actionButton(
					inputId = "choose_right",
					label = "Right/bottom"
				), br(),
				"(wait until plots are updated to click)"
			)
		),
		mainPanel(
			fluidRow(
				column(1, h4("Round")),
				column(1, h4(textOutput("i"))),
				column(1, h4("of")),
				column(1, h4(textOutput("ntot")))
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
					fluidRow(
						column(6, plotOutput("barplot_left")),
						column(6, plotOutput("barplot_right")),
					)
				)
			),
			# Debug mode and fixed seed mode switches
			span(
				actionLink(
					"debugSwitch", "", icon("bug"), style="color:lightgray"
				),
				actionLink(
					"fixSeed", "", icon("dice-five"), style="color:lightgray"
				)
			)
		)
	)
)
