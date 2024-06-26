#' Post stratification estimator helper
#'
#' Calculates predicted values from a multilevel regression and the post-stratified state-level estimates
#'
#' Please see https://book.declaredesign.org/observational-descriptive.html#multi-level-regression-and-poststratification
#'
#' @param model_fit a model fit object from, e.g., glmer or lm_robust
#' @param data a data.frame
#' @param group unquoted name of the group variable to construct estimates for
#' @param weights unquoted name of post-stratification weights variable
#'
#' @return data.frame of post-stratified group-level estimates
#'
#' @export
#'
#' @importFrom marginaleffects predictions
#' @importFrom dplyr group_by summarize
#' @importFrom stats weighted.mean
#' @importFrom rlang `!!` enquo
#'
post_stratification_helper <- function(model_fit, data, group, weights) {
  predictions(
    model_fit,
    newdata = data,
    type = "response"
  ) %>%
    group_by({{group}}) %>%
    summarize(estimate = weighted.mean(estimate, !!enquo(weights)), .groups = "drop")
}
