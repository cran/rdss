
test_that("causal forest helpers work", {

  skip_if_not_installed("grf")

  library(dplyr)
  library(DeclareDesign)
  library(grf)

  covariate_names <- paste0("X.", 1:10)

  f_Y <- function(z, X.1, X.2, X.3, X.4, u)
    z * X.1 + z * X.2 ^ 2 + z * exp(X.3) + z * X.3 * X.4 + u

  get_best_predictor <-
    function(data) select(data, estimate = var_imp) |> slice(1)

  declaration_19.1 <-
    declare_model(
      N = 1000,
      X = matrix(rnorm(10 * N), N),
      U = rnorm(N),
      Z = simple_ra(N)) +
    declare_model(
      Y_Z_1 = f_Y(1, X.1, X.2, X.3, X.4, U),
      Y_Z_0 = f_Y(0, X.1, X.2, X.3, X.4, U),
      tau = Y_Z_1 - Y_Z_0) +
    declare_inquiry(handler = best_predictor,
                    covariate_names = covariate_names,
                    label = "best") +
    declare_measurement(Y = reveal_outcomes(Y ~ Z)) +
    declare_measurement(
      handler = causal_forest_handler,
      covariate_names = covariate_names,
      share_train = 0.5,
      num.threads = 1
    ) +
    declare_measurement(
      handler = fabricate,
      low_test  = (test & (pred < quantile(pred[test], 0.2))),
      low_all = pred < quantile(pred, 0.2)
    ) +
    declare_inquiry(
      ate = mean(tau),
      worst_effects_all = mean(tau[tau <= quantile(tau, 0.2)]),
      worst_effects_test = mean(tau[test & tau <= quantile(tau[test], 0.2)]),
      weak_effects_all = mean(tau[low_all]),
      weak_effects_test = mean(tau[low_test])) +
    declare_estimator(Y ~ Z, inquiry = "ate") +
    declare_estimator(Y ~ Z, subset = low_test,
                      inquiry = c("weak_effects_test", "worst_effects_test"),
                      label = "lm_weak_test") +
    declare_estimator(Y ~ Z, subset = low_all,
                      inquiry = c("weak_effects_all", "worst_effects_all"),
                      label = "lm_weak_all") +
    declare_estimator(handler = label_estimator(get_best_predictor),
                      inquiry = "best_predictor", label = "cf")

  expect_error(simulate_design(declaration_19.1, sims = 1), NA)

})
