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
				"Decision (wait for new number to load)", br(),
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
				selected = "Veri-PRECIOUS",
				tabPanel(
					title = "Veri-PRECIOUS",
					paste(
						"The program will output a number representing the number",
						"of coin-flips out of 100 that come up as heads. Please indicate",
						"whether you think the number indicated is a reasonable example",
						"of a number that might be observed in practice, according to your",
						"personal intuitions as to what might be considered realistic.",
						"You will be shown 100 numbers in total."
					), br(),
					actionLink("start_veri", "Click here to start"), br(),
					h2(uiOutput("final_link_veri")),
					fluidRow(
						column(3, h1("Number: ")),
						column(2, h1(textOutput("ss")))
					),
					plotOutput("finalPlot_veri")
				),
				tabPanel(
					title = "Pari-PRECIOUS",
					paste(
						"The program will output two bar charts, each representing",
						"the distribution of votes between unlabelled political parties in",
						"a random selection of 100 voters. Please select which bar chart",
						"you feel is a more realistic sample of vote distribution in a",
						"specific country. You will be shown 100 pairs of charts in total."
					), br(),
					actionLink("start_pari", "Click here to start"), br(),
					h2(uiOutput("final_link_pari")),
					fluidRow(
						column(6, plotOutput("barplot_left")),
						column(6, plotOutput("barplot_right")),
					),
					plotOutput("finalPlot_pari")
				)
			),
			# Debug mode and fixed seed mode switches
			span(
				span(textOutput("version"), style="color:lightgray"),
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
