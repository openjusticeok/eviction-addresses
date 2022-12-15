#' @title Address Entry Module UI
#'
#' @description UI for the address entry module
#'
#' @param id The module ID
#'
#' @returns The UI for the address entry module
#'
addressEntryUI <- function(id) {
  ns <- NS(id)
  div(
    div(
      style = "display: flex; gap: 10px; justify-content: flex-start; flex-wrap: wrap;",
      textInput(
        inputId = ns("address_street_number"),
        label = "Street Number"
      ),
      textInput(
        inputId = ns("address_street_direction"),
        label = "Street Direction"
      ),
      textInput(
        inputId = ns("address_street_name"),
        label = "Street Name"
      ),
      textInput(
        inputId = ns("address_street_type"),
        label = "Street Type"
      )
    ),
    div(
      style = "display: flex; gap: 10px; justify-content: flex-start; flex-wrap: wrap;",
      textInput(
        inputId = ns("address_street_unit"),
        label = "APT/SUITE/UNIT..."
      )
    ),
    div(
      style = "display: flex; gap: 10px; justify-content: flex-start; flex-wrap: wrap;",
      textInput(
        inputId = ns("address_city"),
        label = "City"
      ),
      selectInput(
        width = "80px",
        inputId = ns("address_state"),
        label = "State",
        choices = c("AR", "OK", "TX"),
        selected = "OK"
      ),
      textInput(
        inputId = ns("address_zip"),
        label = "Zip Code"
      )
    ),
    actionButton(
      inputId = ns("address_validate"),
      label = "Validate"
    )
  )
}

#' @title Address Entry Module Server
#'
#' @description Server for the address entry module
#'
#' @param id The module ID
#' @param config The path to a config file ingested by `{config}`
#' @param db The database connection pool
#' @param current_case The reactive value for the current case
#'
#' @returns The server for the address entry module
#'
addressEntryServer <- function(id, config, db, current_case) {
  api_url <- config::get(
    value = "gcp",
    file = config
  )$service_url
  logger::log_debug("API URL: {api_url}")

  jwt <- reactive({
    invalidateLater(2700000)
    googleCloudRunner::cr_jwt_create(api_url)
  })

  moduleServer(id, function(input, output, session) {
    address_entered <- reactiveValues(
      object = NULL,
      string = NULL
    )
    address_validated <- reactiveValues(
      object = NULL,
      string = NULL
    )
    logger::log_debug("Address Number Input: {input$street_number}")

    observe_address_validation(
      input,
      db,
      current_case,
      jwt,
      api_url,
      address_entered,
      address_validated
    )
    observe_address_submission(
      input,
      db,
      current_case,
      address_entered,
      address_validated
    )
  })
}


#' @title Observe Address Validation
#' 
#' @description This function observes the address validation button and
#'  validates the address.
#' 
#' @param input The input object from the Shiny app
#' @param db The database connection pool
#' @param current_case The reactive value for the current case
#' @param jwt The JWT token for the API
#' @param api_url The URL for the API
#' @param address_entered The reactive values for the address entered
#' @param address_validated The reactive values for the address validated
#' 
#' @returns A Shiny observeEvent object
#'
observe_address_validation <- function(input, db, current_case, jwt, api_url, address_entered, address_validated) {
  observeEvent(input$address_validate, {
    logger::log_debug("Address validation button pressed")

    address_entered$object <- isolate_address_entered(input)
    address_entered$string <- stringify_address_entered(address_entered$object)

    token <- googleCloudRunner::cr_jwt_token(jwt, api_url)
    logger::log_debug("Token: {token}")

    url <- stringr::str_c(api_url, "/address/validate")
    logger::log_debug("URL: {url}")

    logger::log_debug("Address entered: {address_entered$object}")
    res <- googleCloudRunner::cr_jwt_with_httr(
      httr::POST(
        url,
        body = list(
          address = address_entered$object
        ),
        encode = "json"
      ),
      token
    )
    logger::log_debug("Response: {res}")

    modal_content <- shiny::div()
    logger::log_debug("Modal content: {modal_content}")

    if(res$status_code == 200){
      logger::log_debug("Response status code: {res$status_code}")

      response_content <- httr::content(res, as = "parsed", encoding = "UTF-8")
      logger::log_debug("Response content: {response_content}")
      
      address_validated$object <- response_content |>
        purrr::map(purrr::as_vector) |>
        purrr::map(~ifelse(purrr::is_empty(.x), NA_character_, .x))
      logger::log_debug("Address validated: {address_validated$object}")

      logger::log_debug("Is null test: {!is.null(address_validated$object$line1)}")
      if(!is.null(address_validated$object$line1)){
        address_validated$string <- stringify_address_validated(address_validated$object)

        modal_content <- div(
          h5("Address successfully validated"),
          div(
            style = "display: flex; pad: 10px; justify-content: space-around;",
            div(
              h5("Address entered:"),
              h5(HTML(address_entered$string))
            ),
            div(
              h5("Verified address:"),
              h5(HTML(address_validated$string))
            )
          ),
          actionButton("address_submit", label = "Submit", icon = icon("upload"))
        )
      } else {
        modal_content <- "Could not validate address."
        
        query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)
        logger::log_debug("Query: {query}")

      DBI::dbExecute(
          conn = db,
          statement = query
      )
      logger::log_debug("Query executed")
      }
    } else {
      modal_content <- "Bad response from validation server"

      query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case()};', .con = db)
      logger::log_debug("Query: {query}")

      DBI::dbExecute(
        conn = db,
        statement = query
      )
      logger::log_debug("Query executed")

      address_entered$object <- NULL
      address_entered$string <- NULL
      address_validated$object <- NULL
      address_validated$string <- NULL
    }

    showModal(modalDialog(
      title = "Address Validation",
      modal_content
    ))
    logger::log_debug("Modal shown")
  })
}

#' @title Isolate Address Entered
#' 
#' @description This function isolates the address entered by the user.
#' 
#' @param input The input object
#' 
isolate_address_entered <- function(input) {
  address_entered <- list(
    street_number = input$street_number,
    street_direction = input$street_direction,
    street_name = input$street_name,
    street_type = input$street_type,
    city = input$city,
    state = input$state,
    zip = input$zip
  )
  logger::log_debug("Address entered: {address_entered}")

  return(address_entered)
}


#' @title Stringify Address Entered
#' 
#' @description This function prints the address entered by the user.
#' 
#' @param address_entered The address entered by the user
#' 
#' @returns The address entered by the user formatted as a string
#' 
stringify_address_entered <- function(address_entered) {
  address_entered_string <- stringr::str_c(
    address_entered$street_num,
    " ",
    address_entered$street_direction,
    " ",
    address_entered$street_name,
    " ",
    address_entered$street_type,
    "<br>",
    address_entered$unit,
    "<br>",
    address_entered$city,
    ", ",
    address_entered$state,
    " ",
    address_entered$zip
  )
  logger::log_debug("Address entered string: {address_entered_string}")  

  return(address_entered_string)
}

#' @title Stringify Address Validated
#' 
#' @description This function prints the address validated by the API.
#' 
#' @param address_validated The address validated by the API
#' 
#' @returns The address validated by the API formatted as a string
#' 
stringify_address_validated <- function(address_validated) {
  address_validated_string <- stringr::str_c(
    stringr::str_replace_na(address_validated$line1, ""),
    "<br>",
    stringr::str_replace_na(address_validated$line2, ""),
    "<br>",
    stringr::str_replace_na(address_validated$city, ""),
    ", ",
    stringr::str_replace_na(address_validated$state, ""),
    " ",
    stringr::str_replace_na(address_validated$zip, "")
  )
  logger::log_debug("Address string: {address_validated_string}")

  return(address_validated_string)
}

#' @title Observe Address Submission
#' 
#' @description This function observes the address submission button.
#' 
#' @param input The input object
#' @param db The database connection
#' @param current_case The current case
#' @param address_entered The address entered by the user
#' @param address_validated The address validated by the API
#' 
#' @returns A Shiny observer object
#' 
observe_address_submission <- function(input, db, current_case, address_entered, address_validated) {
  observeEvent(input$address_submit, {
    logger::log_debug("Address submit button pressed")

    current_case <- current_case()

    if(is.null(address_validated$object)) {
      rlang::abort("Something is wrong. You submitted an address without first validating.")
    }

    new_row <- tibble::tibble(
      case = current_case(),
      street_number = as.character(address_validated$object$streetNumber),
      street_direction = as.character(address_validated$object$streetDirection),
      street_name = as.character(address_validated$object$streetName),
      street_type = as.character(address_validated$object$streetType),
      city = as.character(address_validated$object$city),
      state = as.character(address_validated$object$state),
      zip = as.character(address_validated$object$zip),
      created_at = lubridate::now(tzone = "America/Chicago"),
      updated_at = lubridate::now(tzone = "America/Chicago"),
      line1 = as.character(address_validated$object$line1),
      line2 = as.character(address_validated$object$line2),
      pre_direction = as.character(address_validated$object$preDirection),
      suite_id = as.character(address_validated$object$suiteID),
      suite_key = as.character(address_validated$object$suiteKey),
      county = as.character(address_validated$object$county),
      country_code = as.character(address_validated$object$country_code),
      country_name = as.character(address_validated$object$country_name),
      zip4 = as.character(address_validated$object$zip4),
      lat = as.character(address_validated$object$lat),
      lon = as.character(address_validated$object$lon),
      geo_accuracy = as.character(address_validated$object$geo_accuracy),
      geo_accuracy_type = as.character(address_validated$object$geo_accuracy_type),
      residential = as.character(address_validated$object$residential),
      vacant = as.character(address_validated$object$vacant),
      firm_name = as.character(address_validated$object$firm_name),
      method = "manual",
      accuracy = "mailing",
      geo_service = "postgrid"
    )
    logger::log_debug("New row: {new_row}")

    write_status <- DBI::dbWriteTable(
      conn = db,
      name = DBI::Id(
        schema = "eviction_addresses",
        table = "address"
      ),
      value = new_row,
      append = TRUE
    )

    if(write_status == TRUE) {
      logger::log_debug("Wrote new record in 'address' table")

      query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET success = TRUE, working = FALSE WHERE "case" = {current_case};', .con = db)

      DBI::dbExecute(
        conn = db,
        statement = query
      )

      logger::log_debug("Set status to success")

      removeModal()
      input$case_refresh
    } else {
      logger::log_error("Failed to write the new record to table 'address'")

      query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)

      update_res <- DBI::dbExecute(
        conn = db,
        statement = query
      )

      if(update_res == 1) {
        logger::log_debug("Incremented attempts by one")
      } else {
        logger::log_debug("{update_res} rows affected by incrementing attempts")
      }
    }

    address_entered$object <- NULL
    address_entered$string <- NULL
    address_validated$object <- NULL
    address_validated$string <- NULL
  })
}