
test_that("tidy_stan works", {

  skip_if_not_installed("rstanarm")

  library(rstanarm)
  library(DeclareDesign)

  declaration_9.3 <-
    declare_model(N = 100, age = sample(0:80, size = N, replace = TRUE)) +
    declare_inquiry(mean_age = mean(age)) +
    declare_sampling(S = complete_rs(N = N, n = 3)) +
    declare_estimator(
      age ~ 1,
      .method = stan_glm,
      family = gaussian(link = "log"),
      prior_intercept = normal(50, 5),
      .summary = ~tidy_stan(., exponentiate = TRUE),
      inquiry = "mean_age"
    )

  expect_error(simulate_design(declaration_9.3, sims = 1), NA)

})
