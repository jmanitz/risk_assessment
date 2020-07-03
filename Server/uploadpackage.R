#####################################################################################################################
# uploadpackage.R - upload pacakge Source file for server Module.
# 
# Author: Aravind
# Created: 02/06/2020.
#####################################################################################################################


# Reactive variable to load the sample csv file into data().

data <- reactive({
  data1<-read_csv("./Data/upload_format.csv")
  data1<-data.table(data1)
  data1
})  # End of the reactive.

# Start of the observe's'

# 1. Observe to load the columns from DB into below reactive values.

observe({
  req(input$total_new_dup)
  if (input$total_new_dup == "Total") {
    values$Total_New_Dup <- values$Total
  } else if (input$total_new_dup == "New") {
    values$Total_New_Dup <- values$New
  } else if (input$total_new_dup == "Duplicates") {
    values$Total_New_Dup <- values$Dup
  } 
})  # End of the observe.

# 2. Observe to disable the input widgets while the packages uploading into DB.
observe({
  req(input$uploaded_file)
  values$uploaded_file_status <- file_upload_error_handling(input$uploaded_file)
  if (values$uploaded_file_status != "no_error") {
    shinyjs::hide("upload_summary_text")
    shinyjs::hide("upload_summary_select")
    shinyjs::hide("total_new_dup_table")
    reset("uploaded_file") 
    return()
  } else{
    shinyjs::show("upload_summary_text")
    shinyjs::show("upload_summary_select")
    shinyjs::show("total_new_dup_table")
  }
  file_to_read <- input$uploaded_file
  pkgs_file <-
    read.csv(file_to_read$datapath,
             sep = ",",
             stringsAsFactors = FALSE)
  names(pkgs_file) <- tolower(names(pkgs_file))
  pkgs_file$package <- trimws(pkgs_file$package)
  pkgs_file$version <- trimws(pkgs_file$version)
  values$Total <- pkgs_file
  pkgs_db1 <- db_fun("SELECT select_packages FROM Select_packages")
  values$Dup <- filter(values$Total, values$Total$package %in% pkgs_db1$select_packages)
  values$New <- filter(values$Total, !(values$Total$package %in% pkgs_db1$select_packages))
  res1 <- db_fun("SELECT select_packages FROM Select_packages")
  values$packsDB <- res1$package
  if(nrow(values$New) != 0){
    for (i in 1:nrow(values$New)) {
      db_fun(paste0("INSERT INTO Select_packages VALUES(", "'",values$New$package[i],"'", ")"))
    }
    total_pkgs_db <- db_fun(paste0("SELECT * FROM Select_packages"))
    updateSelectizeInput(
      session,
      "select_pack",
      choices = c("Select", total_pkgs_db$select_packages),
      selected = "Select"
    )
  }
  showNotification(id = "show_notification_id", "Upload completed to DB", type = "message")
  values$upload_complete <- "upload_complete"
})  # End of the Observe.

# End of the observe's'.

# Start of the render Output's'.
# 1. Render Output to download the sample format dataset.
output$upload_format_download <- downloadHandler(
  filename = function() {
    paste("Upload_file_structure", ".csv", sep = "")
  },
  content = function(file) {
    write.csv(read_csv("./Data/upload_format.csv"), file, row.names = F)
  }
)  # End of the render Output.

# 2. Render Output to show the summary of the uploaded csv into application.

output$upload_summary_text <- renderText({
 if (values$upload_complete == "upload_complete") {
     paste(
       "<h3><b>Summary of:</b>",
       input$uploaded_file$name,
       "</h3>",
       "<h4>Total Packages: ",
       nrow(values$Total),
       "</h4>",
       "<h4>New Packages:",
       nrow(values$New),
       "</h4>",
       "<h4>Duplicate Packages:",
       nrow(values$Dup),
       "</h4>",
       "<h5>Note: The information extracted of the package will be always from latest version irrespective of uploaded version."
    )
  }
})  # End of the render Output.

# 3. Render Output to show the select input to select the choices to display the table.

output$upload_summary_select <- renderUI({
  if (values$upload_complete == "upload_complete") {
    removeUI(selector = "#Upload")
    selectInput(
      "total_new_dup",
      "",
      choices = c("Total", "New", "Duplicates")
    )
  } 
})  # End of the render Output.

# 4. Render Output to show the data table of uploaded csv.
output$total_new_dup_table <- DT::renderDataTable(
  if (values$upload_complete == "upload_complete") {
    datatable(
      values$Total_New_Dup,
      escape = FALSE,
      class = "cell-border",
      selection = 'none',
      extensions = 'Buttons',
      options = list(
        sScrollX = "100%",
        aLengthMenu = list(c(5, 10, 20, 100,-1), list('5', '10', '20', '100', 'All')),
        iDisplayLength = 5
      )
    )
  }
)  # End of the render Output 

# End of the Render Output's'.

# Observe Event for view sample dataset button.
observeEvent(input$upload_format, {
  dataTableOutput("sampletable")
  showModal(modalDialog(
    output$sampletable <- DT::renderDataTable(
      datatable(
        data(),
        escape = FALSE,
        class = "cell-border",
        editable = FALSE,
        filter = "none",
        selection = 'none',
        extensions = 'Buttons',
        options = list(
          sScrollX = "100%",
          aLengthMenu = list(c(5, 10, 20, 100, -1), list('5', '10', '20', '100', 'All')),
          iDisplayLength = 5,
          dom = 't'
        )
      )
    ),
    downloadButton("upload_format_download", "Download", class = "downloaddataset_class btn-secondary")
  ))
})  # End of the observe event for sample button.

# End of the upload package Source file for server Module.