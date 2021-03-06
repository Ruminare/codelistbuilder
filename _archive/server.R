library(shiny)
library(openxlsx)
library(data.table)
library(DT)
library(shinydashboard)

# Read in all source data tables
# icd9 <- data.table(read.xlsx("data/ICD-9-CM-v32-master-descriptions/CMS32_DESC_LONG_SHORT_DX.xlsx"))

icd9 <- data.table(read.xlsx('data/2015-code-descriptions/icd10cm_order_2015_excelformat.xlsx'))
icd9$item <- paste(icd9$DIAGNOSIS.CODE, ' - ', icd9$SHORT.DESCRIPTION)
icd9$item3 <- substr(icd9$DIAGNOSIS.CODE,1,3)

icd10 <- data.table(read.xlsx("data/2015-code-descriptions/icd10cm_order_2015_excelformat.xlsx"))
icd10$VALUE <- trimws(icd10$VALUE, which = "right")
icd10$item <- paste(icd10$VALUE, ' - ', icd10$SHORT.DESCRIPTION)
icd10$item3 <- substr(icd10$VALUE,1,3)

icd9_10GEMS <- data.table(read.table("data/DiagnosisGEMs_2015/2015_I9gem.txt", colClasses = c(rep("character", 3))))
icd10_9GEMS <- data.table(read.table("data/DiagnosisGEMs_2015/2015_I10gem.txt", colClasses = c(rep("character", 3))))

hcpcs <- data.table(read.xlsx("data/HCPC2018_CONTR_ANWEB.xlsx"))
hcpcs$item <- paste(hcpcs$HCPC, ' - ', hcpcs$SHORT.DESCRIPTION)

redbook <- fread("data/redbook/redbook.csv", sep = ",", header= TRUE, colClasses = list(characer=c(1:33)))

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  
  # Server side selectize updating
  updateSelectizeInput(session, 'selected_icd93',  choices = icd9$item3,   server = TRUE)
  updateSelectizeInput(session, 'selected_icd9',   choices = icd9$item,    server = TRUE)
  updateSelectizeInput(session, 'selected_icd103', choices = icd10$item3,  server = TRUE)
  updateSelectizeInput(session, 'selected_icd10',  choices = icd10$item,   server = TRUE)
  updateSelectizeInput(session, 'selected_hcpcs',  choices = hcpcs$item,   server = TRUE)
  updateSelectizeInput(session, 'selected_gennme', choices = redbook$GENNME, server = TRUE)
  updateSelectizeInput(session, 'selected_prodnme', choices = redbook$PRODNME, server = TRUE)
  updateSelectizeInput(session, 'selected_THRCLSD', choices = redbook$THRCLDS, server = TRUE)
  updateSelectizeInput(session, 'selected_routes', choices = redbook$ROADS, server = TRUE)
  
  #callModule(module=regexSelect, id='selected_icd9', reactive(icd9$item))
  
  # Render coding tables for display of selected codes
  output$icd9_table <- DT::renderDataTable({
    DT::datatable(icd9[(icd9$item3 %chin% input$selected_icd93 | icd9$item %chin% input$selected_icd9 | icd9$DIAGNOSIS.CODE %chin% icd10_9GEMS[icd10_9GEMS$V1 %chin% icd10[(icd10$item %chin% input$selected_icd10 | icd10$item3 %chin% input$selected_icd103), ]$VALUE, ]$V2)
                       , c(1,2), drop=FALSE]
                  , options = list(lengthMenu = c(5, 30, 50), pageLength = 5), rownames= FALSE)
  })
  output$icd10_table <- DT::renderDataTable({
    DT::datatable(icd10[(icd10$item3 %chin% input$selected_icd103 | icd10$item %chin% input$selected_icd10 | icd10$VALUE %chin% icd9_10GEMS[icd9_10GEMS$V1 %chin% icd9[(icd9$item %chin% input$selected_icd9 | icd9$item3 %chin% input$selected_icd93), ]$DIAGNOSIS.CODE, ]$V2)
                        , c(1,2,4,5), drop=FALSE]
                  , options = list(lengthMenu = c(5, 30, 50), pageLength = 5), rownames= FALSE)
  })
  output$hcpcs_table <- DT::renderDataTable({
    DT::datatable(hcpcs[hcpcs$item %chin% input$selected_hcpcs, c(1,5,4), drop=FALSE]
                  , options = list(lengthMenu = c(5, 30, 50), pageLength = 5), rownames= FALSE)
  })
  output$ndc_table <- DT::renderDataTable({
    DT::datatable(redbook[((redbook$GENNME %chin% input$selected_gennme | redbook$PRODNME %chin% input$selected_prodnme | redbook$THRCLDS %chin% input$selected_THRCLSD) & (redbook$ROADS %chin% input$selected_routes)), c(1,32,30), drop=FALSE]
                  , options = list(lengthMenu = c(5, 30, 50), pageLength = 5), rownames= FALSE)
  })
  output$ndc_gentable <- DT::renderDataTable({
    ndcdf <- redbook[((redbook$GENNME %chin% input$selected_gennme | redbook$PRODNME %chin% input$selected_prodnme | redbook$THRCLDS %chin% input$selected_THRCLSD) & (redbook$ROADS %chin% input$selected_routes)), c(32), drop=FALSE]
    DT::datatable(unique(ndcdf), options = list(lengthMenu = c(5, 30, 50), pageLength = 5), rownames= FALSE)
  })
  
  # Downloadable csv of selected dataset ----
  output$downloadData <- downloadHandler(
    
    # Shiny saving functions
    filename = function() {
      paste("codelist_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      # Data to be saved
      hcpcs_data <- hcpcs[hcpcs$item %chin% input$selected_hcpcs, c(1:48), drop=FALSE]
      icd9_data  <- icd9[(icd9$item3 %chin% input$selected_icd93 | icd9$item %chin% input$selected_icd9 | icd9$DIAGNOSIS.CODE %chin% icd10_9GEMS[icd10_9GEMS$V1 %chin% icd10[(icd10$item %chin% input$selected_icd10 | icd10$item3 %chin% input$selected_icd103), ]$VALUE, ]$V2)
                         , c(1,2), drop=FALSE]
      icd10_data  <- icd10[(icd10$item3 %chin% input$selected_icd103 | icd10$item %chin% input$selected_icd10 | icd10$VALUE %chin% icd9_10GEMS[icd9_10GEMS$V1 %chin% icd9[(icd9$item %chin% input$selected_icd9 | icd9$item3 %chin% input$selected_icd93), ]$DIAGNOSIS.CODE, ]$V2)
                           , c(1,2,4,5), drop=FALSE]
      ndc_data <- redbook[((redbook$GENNME %chin% input$selected_gennme | redbook$PRODNME %chin% input$selected_prodnme | redbook$THRCLDS %chin% input$selected_THRCLSD) & (redbook$ROADS %chin% input$selected_routes)), 
                          c(1,32,30, c(2:29), 33), drop=FALSE]
      # Organized workbook format
      wb <- createWorkbook()
      addWorksheet(wb = wb, sheetName = "ICD9", gridLines = TRUE)
      writeDataTable(wb = wb, sheet = "ICD9", x = icd9_data, rowNames=TRUE)
      addWorksheet(wb = wb, sheetName = "ICD10", gridLines = TRUE)
      writeDataTable(wb = wb, sheet = "ICD10", x = icd10_data, rowNames=TRUE)
      addWorksheet(wb = wb, sheetName = "HCPCS", gridLines = TRUE)
      writeDataTable(wb = wb, sheet = "HCPCS", x = hcpcs_data, rowNames=TRUE)
      addWorksheet(wb = wb, sheetName = "NDC", gridLines = TRUE)
      writeDataTable(wb = wb, sheet = "NDC", x = ndc_data, rowNames=TRUE)
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
})
