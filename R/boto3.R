#' Boto3
#'
boto3 <- NULL

#' On Load
#'
#' @param libname
#' @param pkgname
#'
#' @return
#' @export
#'
#' @examples
.onLoad <- function(libname, pkgname) {
  # delay load boto3 module (will only be loaded when accessed via $)
  boto3 <<- reticulate::import("boto3", delay_load = T)
}

#' @title Install Boto3
#'
#' @param method A string (character vector length one)
#' @param conda A string (character vector length one)
#'
#' @return
#' @export
#'
#' @examples
install_boto3 <- function(method = "auto", conda = "auto") {
  reticulate::py_install(packages = "boto3", method = method, conda = conda)
}
