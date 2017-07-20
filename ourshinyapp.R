library(leaflet)
library(shiny)
library(ggplot2)
library(ggmap) 
library(plotGoogleMaps) 
library(RColorBrewer)


Arlin0 <- read.csv("apartments_full.csv", header = TRUE)

Arlin1 <-  Arlin0[!is.na(Arlin0$Rent), ]
Arlin2 <- Arlin1[!is.na(Arlin1$Metro.Distance), ]

uia1 <- bootstrapPage(
    tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
    leafletOutput("map", width = "100%", height = "100%"),
    absolutePanel(top = 10, right = 10,
                  sliderInput("range", "Rent", min(Arlin2$Rent), max(Arlin2$Rent),
                              value = range(Arlin2$Rent), step = 100
                  ),
                  sliderInput("metro", "Distance to Metro (meters)", min(round(Arlin2$Metro.Distance , digits=0)), max(round(Arlin2$Metro.Distance , digits=0)),
                              value = range(round(Arlin2$Metro.Distance , digits=0)), step = 1000
                  ),
                  selectInput("zip", "Zip code", unique(Arlin2$Zip), multiple = FALSE,
                              helpText("Zip codes")),
                  selectInput("City", "City", unique(Arlin2$City))
                  
    )
)

servera1 <- function(input, output, session) {
    
    # Reactive expression for the data subsetted to what the user selected
    filteredData <- reactive({
        Arlin2[(Arlin2$Metro.Distance >= input$metro[1] & Arlin2$Metro.Distance <= input$metro[2]) & (Arlin2$Rent >= input$range[1] & Arlin2$Rent <= input$range[2]) & (Arlin2$Zip == input$zip),]
    })
    
    # This reactive expression represents the palette function,
    # which changes as the user makes selections in UI.
    
    
    output$map <- renderLeaflet({
        # Use leaflet() here, and only include aspects of the map that
        # won't need to change dynamically (at least, not unless the
        # entire map is being torn down and recreated).
        leaflet(Arlin2) %>% addTiles() %>%
            fitBounds(~min(Longitude), ~min(Latitude), ~max(Longitude), ~max(Latitude))
    })
    
    # Incremental changes to the map (in this case, replacing the
    # circles when a new color is chosen) should be performed in
    # an observer. Each independent set of things that can change
    # should be managed in its own observer.
    observe({
        thedata <- filteredData()
        city_popup <- paste0("<strong> Name: </strong>",
                             thedata$Name,
                             "<br><strong> Rent: </strong>$",
                             thedata$Rent,
                             "<br><strong> Zip: </strong>",
                             input$zip,
                             "<br><strong> Distance to metro: </strong>",
                             thedata$Metro.Distance)
        color = "#04F" 
        leafletProxy("map", data = thedata) %>%
            clearShapes() %>%
            addCircles(radius = ~sqrt(Rent)*0.7, weight = 2,
                       fillColor = color , fill = TRUE, fillOpacity = 0.7, popup = city_popup
            )
    })
    
    # Use a separate observer to recreate the legend as needed.
    
}


shinyApp(ui = uia1, server = servera1)