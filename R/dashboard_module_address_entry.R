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
#' 
#' @returns The server for the address entry module
#' 
addressEntryServer <- function(id, config, db) {
  api_url <- config::get(
    value = "gcp",
    file = config
  )$service_url

  jwt <- reactive({
    invalidateLater(2700000)
    googleCloudRunner::cr_jwt_create(api_url)
  })

  moduleServer(id, function(input, output, session) {
    address_entered <- NULL
    address_validated <- NULL

    observeEvent(input$address_validate, {

      address_entered <<- list(
        street_num = isolate(input$address_street_number),
        street_direction = isolate(input$address_street_direction),
        street_name = isolate(input$address_street_name),
        street_type = isolate(input$address_street_type),
        unit = isolate(input$address_street_unit),
        city = isolate(input$address_city),
        state = isolate(input$address_state),
        zip = isolate(input$address_zip)
      )

      address_entered_string <- stringr::str_c(address_entered$street_num,
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
                                               address_entered$zip)

      token <- googleCloudRunner::cr_jwt_token(jwt(), api_url)
      url <- stringr::str_c(api_url, "/address/validate")

      res <- googleCloudRunner::cr_jwt_with_httr(
        httr::POST(
          url,
          body = address_entered,
          encode = "json"
        ),
        token
      )

      modal_content <- div()

      if(res$status_code == 200){
        response_content <- httr::content(res, as = "parsed", encoding = "UTF-8")
        logger::log_debug("Response content: {response_content}")

        address_validated <<- response_content |>
          purrr::map(purrr::as_vector) |>
          purrr::map(~ifelse(purrr::is_empty(.x), NA_character_, .x))
        logger::log_debug("Address validated: {address_validated}")

        logger::log_debug("Is null test: {!is.null(address_validated$line1)}")
        if(!is.null(address_validated$line1)){
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

          modal_content <- div(
            h5("Address successfully validated"),
            div(
              style = "display: flex; pad: 10px; justify-content: space-around;",
              div(
                h5("Address entered:"),
                h5(HTML(address_entered_string))
              ),
              div(
                h5("Verified address:"),
                h5(HTML(address_validated_string))
              )
            ),
            actionButton("address_submit", label = "Submit", icon = icon("upload"))
          )
        } else {
          modal_content <- "Could not validate address."

          query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)

          DBI::dbExecute(
            conn = db,
            statement = query
          )
        }
      } else {
        modal_content <- "Bad response from validation server"

        query <- glue::glue_sql('UPDATE "eviction_addresses"."queue" SET attempts = attempts + 1, working = FALSE WHERE "case" = {current_case};', .con = db)

        DBI::dbExecute(
          conn = db,
          statement = query
        )
      }

      showModal(modalDialog(
        title = "Address Validation",
        modal_content
      ))

    })

    observeEvent(input$address_submit, {

      current_case <- current_case()

      if(!exists("address_entered") | !exists("address_validated")) {
        rlang::abort("Something is wrong. You submitted an address without first validating.")
      } else {

        new_row <- tibble::tibble(
          case = current_case(),
          street_number = as.character(address_validated$streetNumber),
          street_direction = as.character(address_validated$streetDirection),
          street_name = as.character(address_validated$streetName),
          street_type = as.character(address_validated$streetType),
          city = as.character(address_validated$city),
          state = as.character(address_validated$state),
          zip = as.character(address_validated$zip),
          created_at = lubridate::now(tzone = "America/Chicago"),
          updated_at = lubridate::now(tzone = "America/Chicago"),
          line1 = as.character(address_validated$line1),
          line2 = as.character(address_validated$line2),
          pre_direction = as.character(address_validated$preDirection),
          suite_id = as.character(address_validated$suiteID),
          suite_key = as.character(address_validated$suiteKey),
          county = as.character(address_validated$county),
          country_code = as.character(address_validated$country_code),
          country_name = as.character(address_validated$country_name),
          zip4 = as.character(address_validated$zip4),
          lat = as.character(address_validated$lat),
          lon = as.character(address_validated$lon),
          geo_accuracy = as.character(address_validated$geo_accuracy),
          geo_accuracy_type = as.character(address_validated$geo_accuracy_type),
          residential = as.character(address_validated$residential),
          vacant = as.character(address_validated$vacant),
          firm_name = as.character(address_validated$firm_name),
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
          append = T
        )

        if(write_status == T) {
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
      }
    })
  })
}
