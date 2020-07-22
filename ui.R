## ---------------------------
##
## COVID19 Event Risk Assessment Planning tool
##
## Aroon Chande <mail@aroonchande.com> <achande@ihrc.com>
## Lavanya Rishsishwar <lrishishwar@ihrc.com>
## Model from Joshua Weitz
## See: https://github.com/jsweitz/covid-19-ga-summer-2020
## ---------------------------
library(shiny)
library(shinythemes, lib.loc = "/projects/covid19/covid19/R/x86_64-redhat-linux-gnu-library/3.6/")
library(shinyWidgets)
library(leaflet)
options(scipen = 999)

timeoutSeconds <- 120

inactivity <- sprintf("function idleTimer() {
var t = setTimeout(logout, %s);
window.onmousemove = resetTimer; // catches mouse movements
window.onmousedown = resetTimer; // catches mouse movements
window.onclick = resetTimer;     // catches mouse clicks
window.onscroll = resetTimer;    // catches scrolling
window.onkeypress = resetTimer;  //catches keyboard actions

function logout() {
Shiny.setInputValue('timeOut', '%ss')
}

function resetTimer() {
clearTimeout(t);
t = setTimeout(logout, %s);  // time is in milliseconds (1000 is 1 second)
}
}
idleTimer();", timeoutSeconds*1000, timeoutSeconds, timeoutSeconds*1000)

shinyUI(fluidPage(
  theme = shinytheme("sandstone"),
  tags$script(inactivity), 
  tags$head(
    includeHTML(("www/ga.html")),
    includeHTML(("www/mt.html")),
    tags$style(
      ".map-container {
          height: 600px;
          width: 100%;
          position: relative;
        }",
      ".map-loading {
          position: absolute;
          display: flex;
          justify-content: center;
          align-items: center;
          width: 100%;
          height: 600px;
          background-color: #bdbdbd;
          text-align: center;
          color: #FFFFFF;
          font-size: 2em;
        }"
    )
  ),
  # Application title
  titlePanel(titlePanel(
   h2(
      "COVID-19 Event Risk Assessment Planning Tool"
    )
    # column(width = 3, tags$img(src = "scaled_plot.jpg"))
  ), windowTitle = "COVID-19 Event Risk Assessment Planning Tool"),
  tabsetPanel(
    tabPanel(
      id = "Map",
      title = "Risk estimates by county",
      fluid = TRUE,
      sidebarLayout(
        sidebarPanel(
          width=2,
        HTML(
          paste0(
            "<p>This map shows the risk level of attending an event, given the event size and location (assuming 10:1 ascertainment bias).",
            "<br/><br/>",
            "The risk level is the estimated chance (0-100%) that at least 1 COVID-19 positive individual will be present at an event in a county, given the size of the event",
            "<br/><br/>",
            "Choose an event size. Use the drop-down menu to choose a county you would like to zoom in on.</p>"
          )
        ),
        shinyWidgets::sliderTextInput(
              "event_size_map",
              "Event Size: ",
              choices = c(10, 25, 50, 100, 500, 1000, 5000, 10000),
              selected = 100,
              grid = T
            ),
        shinyWidgets::awesomeRadio(
          inputId = "asc_bias",
          label = "Select Ascertainment Bias", 
          choices = c("2", "5", "10", "15"),
          selected = "10",
          status = "warning"
        )
        # selectizeInput("county_text", 
        #       "Center map on county:", 
        #       choices = NULL),
            # column(2,
            # actionButton("zoom_county", 
            #   label = "Go to a county")
            # ),
            # column(2,
            # downloadButton("dl_map", 
            #   label = "Download map")
            # )
        ),
      mainPanel(
        fluidRow(column(
          10,
            htmlOutput("map_static", width = "992px", height = "744px")
          # ),
        )),
        HTML(
          "<p>(Note: This map uses a Web Mercator projection that inflates the area of states in northern latitudes. County boundaries are generalized for faster drawing.)</p>"
        )
      )
      )
    ),
    tabPanel(
      id = "Data-driven",
      "Real-time US and State-level estimates ",
      # 
      fluid = TRUE,
      sidebarLayout(
        sidebarPanel(
          width=3,
          HTML(
            "<p>The horizontal dotted lines with risk estimates are based on real-time COVID19 surveillance data.
                  They represent estimates given the current reported incidence [C<sub>I</sub>] (<span title='circle' style='color: red'>&#11044;</span>), 5 times the current incidence (<span title='triangle' style='color: red'>&#9650;</span>), and 10 times the current incidence (<span title='square' style='color: red'>&#9632;</span>).
                  These estimates help understand the effects of potential under-testing and reporting of COVID19 incidence.</p>"
          ),
          htmlOutput("dd_current_data"),
          checkboxInput("use_state_dd", label = "Limit prediction to state level?", value = TRUE),
          conditionalPanel(
            condition = "input.use_state_dd",
            selectizeInput("states_dd", "Select state", c())
          ),
          textInput("event_dd",
            "Event size:",
            value = 275
          ),
          downloadButton("dl_dd", "Download plot"),
          htmlOutput("dd_text")
        ),

        mainPanel( # verbatimTextOutput("values_dd"),br(),
          plotOutput(
            "plot_dd",
            width = "900px", height = "900px"
          )
        )
      )
    ),
    tabPanel(
      id = "Prediction",
      "Explore US and State-level estimates",
      fluid = TRUE,
      sidebarLayout(
        sidebarPanel(
          width=3,
          textInput(
            "event_size_us",
            "Event size:",
            value = 275,
            placeholder = 450
          ),
          textInput(
            "infect_us",
            "Number of circulating infections:",
            value = 800000,
            placeholder = "250,000"
          ),
          checkboxInput("use_state", label = "Limit prediction to state level?"),
          conditionalPanel(
            condition = "input.use_state",
            selectizeInput("us_states", "Select state", c())
          ),
          conditionalPanel(
            condition = "input.use_state",
            p(
              "The dashed horizontal lines with estimates represent 1%, 5%, and 25% of the population being infected"
            )
          ),
          actionButton("calc_us", label = "What is the risk?"),
          downloadButton("dl_pred", "Download plot")
        ),

        mainPanel( # verbatimTextOutput("values"),br(),
          plotOutput(
            "plot_us",
            width = "900px", height = "900px"
          )
        )
      )
    ),
    #
    tabPanel(
      id = "risk_estimates",
      "Continuous risk estimates",
      fluid = TRUE,
      sidebarLayout(
        sidebarPanel(
          width=3,
          HTML(
            "<p>The curved lines (risk estimates) are based on real-time COVID19 surveillance data.
                  They represent estimates given the current reported incidence (dashed line) [C<sub>I</sub>]: 5x the current incidence (blue), 10x (yellow), and 20x (red).
                  These estimates help understand the effects of potential under-testing and reporting of COVID19 incidence.</p>
                  <p>Select from a mosiac of all 50 states, ordered alphabetically or by their population-adjusted incidence, or zoom in to individual states.</p>"
          ),
          selectizeInput("regions", "Select region", c()),
          selectizeInput("date", "Select a date to view", c()),
          p(
            "Estimates are updated every day at midnight and 12:00 (timezone=America/New_York)"
          ),
          downloadButton("dl_risk", "Download plot")
        ),
        mainPanel(plotOutput(
          "risk_plots",
          width = "900px", height = "900px"
        ))
      )
    ),
    tabPanel(
      id = "previous",
      "Previously Released Charts",
      fluid = TRUE,
      mainPanel(
        tags$img(src = "twitter_image_031020.jpg"),
        tags$br(),
        tags$br(),
        tags$img(src = "figevent_checker_apr30.png"),
        tags$br(),
        tags$br(),
        tags$img(src = "figevent_checker_georgia_042720.jpg  ")
      )
    ),
    tabPanel(
      id = "tuts",
      "Tutorial",
      fluid = TRUE,
      mainPanel(includeMarkdown("Tutorial.md"))
    ),
    tabPanel(
      id = "data",
      "Data source",
      fluid = TRUE,
      mainPanel(includeMarkdown("Data.md"))
    ),
    tabPanel(
      id = "press",
      "Press",
      fluid = TRUE,
      mainPanel(includeMarkdown("Press.md"))
    ),
    tabPanel(
      id = "about",
      "About",
      fluid = TRUE,
      mainPanel(includeMarkdown("About.md"))
    )
     ),
  tags$div(
    class = "footer",
    align = "center",
    # style = "position: absolute; bottom: 0; width:100%; z-index:1000; heght 50px",
    column(width = 2),
    column(width = 2, tags$a(href = "https://www.gatech.edu/", tags$img(src = "gt-logo-gold.png"))),
    # column(width = 2),
    column(
      width = 2,
      tags$a(href = "https://www.abil.ihrc.com/?covid19-risk", tags$img(src = "ABiL-Logo.png"))
    ),
    column(width = 2)
  )
))
