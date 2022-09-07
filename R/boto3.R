boto3 <- NULL

rlang::on_load(
  boto3 <<- reticulate::import("boto3", delay_load = T)
)

#' @title Install Boto3
#'
#' @param method A string (character vector length one)
#' @param conda A string (character vector length one)
#'
#' @export
#'
install_boto3 <- function(method = "auto", conda = "auto") {
  reticulate::py_install(packages = "boto3", method = method, conda = conda)
}
