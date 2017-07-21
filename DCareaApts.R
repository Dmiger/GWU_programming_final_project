library(leaflet)
library(shiny)
library(ggplot2)
library(ggmap)
library(plotGoogleMaps)
library(RColorBrewer)
 


Arl <- read.csv("apartments_full.csv", header = TRUE)

#______________________________________#

Arl2 <- subset(Arl, select = c(Name, Address, City, Zip, Num.bedrooms, Rent, Pets.Allowed, Latitude, Longitude, Metro.Distance))
Arlz <-  Arl2[!is.na(Arl2$Rent), ]
Arl3 <- Arlz[!is.na(Arlz$Metro.Distance), ]


#_______________________________________#

shinyApp(
    ui = bootstrapPage(
    tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
    leafletOutput("map", width = "100%", height = "100%"),
    absolutePanel(top = 10, right = 10,
                  sliderInput("range", "Monthly rent", min(Arl3$Rent), max(Arl3$Rent),
                              value = range(Arl3$Rent), step = 1
                  ),
                  selectInput("colors", "Color Scheme",
                              rownames(subset(brewer.pal.info, category %in% c("seq", "div")))
                  ),
                  checkboxInput("legend", "Show legend", TRUE)
        )
    ),

    server = function(input, output, session) {
    
    # Reactive expression for the data subsetted to what the user selected
    filteredData <- reactive({
        Arl3[Arl3$Rent >= input$range[1] & Arl3$Rent <= input$range[2],]
    })
    
    # This reactive expression represents the palette function,
    # which changes as the user makes selections in UI.
    colorpal <- reactive({
        colorNumeric(input$colors, Arl3$Rent)
    })
    
    output$map <- renderLeaflet({
        # Use leaflet() here, and only include aspects of the map that
        # won't need to change dynamically (at least, not unless the
        # entire map is being torn down and recreated).
        leaflet(Arl3) %>% addTiles() %>%
            fitBounds(~min(Longitude), ~min(Latitude), ~max(Longitude), ~max(Latitude))
    })
    
    # Incremental changes to the map (in this case, replacing the
    # circles when a new color is chosen) should be performed in
    # an observer. Each independent set of things that can change
    # should be managed in its own observer
    observe({
        pal <- colorpal()
        thedata <- filteredData()
        city_popup2 <- paste0("<strong> Name: </strong>",
                             thedata$Name,
                             "<br><strong> Rent: </strong>$",
                             thedata$Rent,
                             "<br><strong> Zip: </strong>",
                             thedata$Zip,
                             "<br><strong> Bedrooms: </strong>",
                             thedata$Num.bedrooms,
                             "<br><strong> Pets allowed: </strong>",
                             thedata$Pets.Allowed,
                             "<br><strong> Distance to metro: </strong>",
                             (round(thedata$Metro.Distance , digits=0)))
        leafletProxy("map", data = filteredData()) %>%
            clearShapes() %>%
            addCircles(radius = (Arl3$Num.bedrooms)^1.2 + 12, weight = 3, color = "deeppink",
                       fillColor = ~pal(Rent), fillOpacity = 4 , popup = city_popup2
            )
    })
    
    # Use a separate observer to recreate the legend as needed.
    observe({
        proxy <- leafletProxy("map", data = Arl3)
        
        # Remove any existing legend, and only if the legend is
        # enabled, create a new one.
        proxy %>% clearControls()
        if (input$legend) {
            pal <- colorpal()
            proxy %>% addLegend(position = "bottomright",
                                pal = pal, values = ~Rent
            )
        }
    })
})
