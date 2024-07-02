# FASTA and Metadata File Filtering Shiny App

This repository contains a Shiny application that allows users to filter FASTA and metadata files based on selected localities, date range, state/province, and cluster. The application reads the input files, applies the filters, and outputs the filtered data.

## Features

- User-friendly interface for selecting and filtering FASTA and metadata files.
- Multiple filter options including locality, date range, state/province, and cluster.
- Generates filtered FASTA and metadata files.
- Provides a bar plot visualization of the filtered metadata.

## Requirements

- R (version 4.0 or later)
- RStudio (optional but recommended)

### R Packages

The following R packages are required to run the app:

- shiny
- shinythemes
- dplyr
- Biostrings
- tools
- lubridate
- ggplot2
- readxl
- writexl

- sage
Clone the repository:

bash
Copy code
git clone https://github.com/your-username/fasta-metadata-filter-shiny-app.git
Navigate to the project directory:

bash
Copy code
cd fasta-metadata-filter-shiny-app
Run the Shiny app:

Open app.R in RStudio or run the following command in your R console:

r
Copy code
shiny::runApp('app.R')
Upload the files:

Choose the FASTA file (.fas, .fa, .fasta).
Choose the metadata file (.xlsx).
Apply filters:

Select the desired state/province.
Select the localities.
Select the clusters.
Set the date range.
Filter and download:

Click on the Filter Files button to filter the data. The filtered FASTA and metadata files will be saved in the filtered_files directory.

You can install these packages using the following commands:

```r
install.packages(c("shiny", "shinythemes", "dplyr", "tools", "lubridate", "ggplot2", "readxl", "writexl"))
BiocManager::install("Biostrings")
