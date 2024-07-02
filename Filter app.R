library(shiny)
library(shinythemes)
library(dplyr)
library(Biostrings)
library(tools)
library(lubridate)
library(ggplot2)
library(readxl)
library(writexl)

# Function to filter FASTA and metadata files based on selected filters
filter_fasta_metadata <- function(fasta_file, metadata_file, selected_localities, date_range, selected_stateprov, selected_cluster, output_dir) {
  # Read the FASTA file
  sequences <- readDNAStringSet(fasta_file)
  
  # Read the metadata file (Excel)
  metadata <- read_excel(metadata_file)
  
  # Convert the onsetdate column to Date type
  metadata$onsetdate <- as.Date(metadata$onsetdate, tryFormats = c("%Y-%m-%d", "%m/%d/%Y", "%d-%m-%Y"))
  
  # Filter metadata by selected localities, date range, StateProv, and Cluster
  filtered_metadata <- metadata %>%
    filter(StateProv %in% selected_stateprov & 
             locality %in% selected_localities & 
             onsetdate >= date_range[1] & onsetdate <= date_range[2] & 
             Cluster %in% selected_cluster)
  
  # Get the sequence names to keep
  seq_names <- filtered_metadata$FILENAME
  
  # Ensure the sequence names exist in the sequences object
  valid_seq_names <- intersect(seq_names, names(sequences))
  if(length(valid_seq_names) != length(seq_names)) {
    warning("Some sequence names in metadata do not match the names in the FASTA file.")
  }
  
  # Filter the sequences by names
  filtered_sequences <- sequences[valid_seq_names]
  
  # Define output file names
  fasta_output_file <- file.path(output_dir, paste0(file_path_sans_ext(basename(fasta_file)), "_filtered.fas"))
  metadata_output_file <- file.path(output_dir, paste0(file_path_sans_ext(basename(metadata_file)), "_filtered.xlsx"))
  
  # Write the filtered sequences to a new FASTA file
  writeXStringSet(filtered_sequences, fasta_output_file)
  
  # Write the filtered metadata to a new Excel file
  write_xlsx(filtered_metadata, metadata_output_file)
  
  return(list(fasta_output_file = fasta_output_file, metadata_output_file = metadata_output_file))
}

# Create a Shiny app for file selection and filtering
shinyApp(
  ui = fluidPage(
    theme = shinytheme("cosmo"), # Change the theme as desired
    tags$head(
      tags$style(HTML("
        body {
          background: url('background.jpg') no-repeat center center fixed;
          background-size: cover;
        }
        .overlay {
          background-color: rgba(255, 255, 255, 0.8);
          padding: 20px;
          border-radius: 10px;
        }
        .title-panel {
          position: relative;
          padding: 10px;
          color: white;
        }
        .title-panel .logo {
          position: absolute;
          top: 10px;
          right: 10px;
          height: 100px;
        }
        .background-overlay {
          position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); /* Black overlay with 50% opacity */
          z-index: -1; /* Ensure it stays behind the content */
        }
      "))
    ),
    div(class = "background-overlay"), # Div for the overlay
    titlePanel(
      div(class = "title-panel",
          h1("Filter Fasta and Metadata Files"),
          img(src = "logo.png", class = "logo")
      )
    ),
    sidebarLayout(
      sidebarPanel(
        div(class = "overlay",
            fileInput("fastaFile", "Choose FASTA File", accept = c(".fas", ".fa", ".fasta")),
            fileInput("metadataFile", "Choose Metadata File", accept = c(".xlsx")),
            uiOutput("stateprov_ui"),
            uiOutput("locality_ui"),
            uiOutput("cluster_ui"),
            uiOutput("date_ui"),
            actionButton("filterButton", "Filter Files")
        )
      ),
      mainPanel(
        div(class = "overlay",
            textOutput("result"),
            hr(),
            plotOutput("countPlot"),
            p("Created by: Polio Team Pakistan", style = "text-align: right; font-style: italic;")
        )
      )
    )
  ),
  
  server = function(input, output, session) {
    observe({
      req(input$metadataFile)
      
      # Read metadata file to get unique values for filters
      metadata <- read_excel(input$metadataFile$datapath)
      
      # Check and convert onsetdate column to Date type
      metadata$onsetdate <- as.Date(metadata$onsetdate, tryFormats = c("%Y-%m-%d", "%m/%d/%Y", "%d-%m-%Y"))
      
      unique_stateprov <- unique(metadata$StateProv)
      date_range <- range(metadata$onsetdate, na.rm = TRUE)
      
      # Update UI to select StateProv
      output$stateprov_ui <- renderUI({
        selectInput("selectedStateprov", "Select StateProv", choices = unique_stateprov, multiple = TRUE)
      })
      
      observeEvent(input$selectedStateprov, {
        filtered_metadata <- metadata %>% filter(StateProv %in% input$selectedStateprov)
        unique_localities <- unique(filtered_metadata$locality)
        
        output$locality_ui <- renderUI({
          selectInput("selectedLocalities", "Select Localities", choices = unique_localities, multiple = TRUE)
        })
      })
      
      observeEvent(input$selectedLocalities, {
        req(input$selectedStateprov)
        
        filtered_metadata <- metadata %>% filter(StateProv %in% input$selectedStateprov & locality %in% input$selectedLocalities)
        unique_cluster <- unique(filtered_metadata$Cluster)
        
        output$cluster_ui <- renderUI({
          selectInput("selectedCluster", "Select Cluster", choices = unique_cluster, multiple = TRUE)
        })
      })
      
      # Update UI to select date range
      output$date_ui <- renderUI({
        dateRangeInput("dateRange", "Select Date Range", start = date_range[1], end = date_range[2])
      })
    })
    
    observeEvent(input$filterButton, {
      req(input$fastaFile)
      req(input$metadataFile)
      req(input$selectedStateprov)
      req(input$selectedLocalities)
      req(input$dateRange)
      req(input$selectedCluster)
      
      # Get original file paths
      fasta_path <- input$fastaFile$datapath
      metadata_path <- input$metadataFile$datapath
      
      # Define the output directory within the app directory
      output_dir <- "filtered_files"
      if (!dir.exists(output_dir)) {
        dir.create(output_dir)
      }
      
      # Use output directory for processing
      result <- filter_fasta_metadata(fasta_path, metadata_path, input$selectedLocalities, input$dateRange, input$selectedStateprov, input$selectedCluster, output_dir)
      
      output$result <- renderText({
        paste("Filtered FASTA file saved to:", result$fasta_output_file, "\n",
              "Filtered metadata file saved to:", result$metadata_output_file)
      })
      
      # Render plot based on filtered metadata
      output$countPlot <- renderPlot({
        filtered_metadata <- read_excel(result$metadata_output_file)
        
        ggplot(filtered_metadata, aes(x = locality, fill = Cluster)) +
          geom_bar(position = "stack") +
          labs(title = "Count of Sequences per Locality", x = "Locality", y = "Count", fill = "Cluster") +
          theme_minimal()
      })
    })
  }
)
