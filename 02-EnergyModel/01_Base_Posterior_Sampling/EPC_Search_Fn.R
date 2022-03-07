# EPC_Search_Fn.R
# This script contains functions for searching and retrieving required SUSDEM inputs from the EPC API
# Update 14 Feb 22 - Fixed sample size change in API and filter old uprn duplicates

require(httr)
require(jsonlite)

# Base LAD search function
EPC_Search <- function(LA_no){
  postcode <- LA_no
  
  epc_root <- paste0("https://epc.opendatacommunities.org/api/v1/domestic/search?accept=application/json&local-authority=",postcode,"&size=5000")
  
  epc_pull <- httr::GET(url=epc_root, authenticate("apn30@cam.ac.uk","d162f191c46b4aae29e4adfbfa5a30b63891f556"), accept_json())
  httr::http_status(epc_pull)
  
  epc_data <-  jsonlite::fromJSON(txt=httr::content(epc_pull, "text"))
  
  epc_df <- as.data.frame(epc_data$rows)
  
  epc_df <- epc_df[order(epc_df$`inspection-date`),]
  epc_df <- epc_df[!duplicated(epc_df$'uprn', fromLast=TRUE) , ]
  
  return(epc_df)
}

# Postcode-level search function
EPC_Search_postcode <- function(LA_no){
  postcode <- LA_no
  
  epc_root <- paste0("https://epc.opendatacommunities.org/api/v1/domestic/search?accept=application/json&postcode=",postcode,"&size=5000")
  
  epc_pull <- httr::GET(url=epc_root, authenticate("apn30@cam.ac.uk","d162f191c46b4aae29e4adfbfa5a30b63891f556"), accept_json())
  httr::http_status(epc_pull)
  
  epc_data <-  jsonlite::fromJSON(txt=httr::content(epc_pull, "text"))
  
  epc_df <- as.data.frame(epc_data$rows)
  
  epc_df <- epc_df[order(epc_df$`inspection-date`),]
  epc_df <- epc_df[!duplicated(epc_df$'uprn', fromLast=TRUE) , ]
  
  return(epc_df)
}

EPC_Cal_Request <- function(LA_no){
  search_terms <- c("bungalow","flat","house","maisonette")
  EPC_Search_Comp <- NULL
  for(i in search_terms){
    epc_cal_req <- paste0(postcode,"&property-type=",i)
    carry_df <- EPC_Search(epc_cal_req)
    EPC_Search_Comp <- rbind(EPC_Search_Comp
    
  }
}
