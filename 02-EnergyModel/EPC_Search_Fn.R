# EPC_Search_Fn.R
# This script contains functions for searching and retrieving required SUSDEM inputs from teh EPC API

require(httr)
require(jsonlite)

postcode <- "CB3"

epc_root <- paste0("https://epc.opendatacommunities.org/api/v1/domestic/search?accept=application/json&postcode=",postcode)

epc_pull <- httr::GET(url=epc_root, authenticate("apn30@cam.ac.uk","d162f191c46b4aae29e4adfbfa5a30b63891f556"), accept_json())
httr::http_status(epc_pull)

epc_data <-  jsonlite::fromJSON(txt=httr::content(epc_pull, "text"))

epc_df <- as.data.frame(epc_data$rows)
