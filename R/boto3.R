#' @title Install Boto3
#'
#' @param method A string (character vector length one)
#' @param conda A string (character vector length one)
#'
#' @export
#'
install_boto3 <- function(method = "auto", conda = "auto") {
  reticulate::virtualenv_create(envname = "./reticulate-env", packages = "boto3")
# reticulate::py_install(packages = "boto3", method = method, conda = conda)
}
