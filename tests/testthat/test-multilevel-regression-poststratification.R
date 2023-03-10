
test_that("post_stratification_helper works", {

  skip_if_not_installed("lme4")

  library(DeclareDesign)
  library(lme4)

  states <-
    as_tibble(state.x77) |>
    transmute(
      state = rownames(state.x77),
      prop_of_US = Population / sum(Population),
      # results in exactly 2,000 due to rounding
      state_n = round(prop_of_US * 1998.6),
      prob_HS = `HS Grad` / 100,
      state_shock = rnorm(n = n(), sd = 0.5),
      state_mean = prob_HS * pnorm(0.2 + state_shock) + (1 - prob_HS) * pnorm(state_shock)
    )

  declaration_15.4 <-
    declare_model(
      data = states[rep(1:50, states$state_n), ],
      HS = rbinom(n = N, size = 1, prob = prob_HS),
      PS_weight =
        case_when(HS == 0 ~ (1 - prob_HS),
                  HS == 1 ~ prob_HS),
      individual_shock = rnorm(n = N, sd = 0.5),
      policy_support =
        rbinom(N, 1, prob = pnorm(0.2 * HS + individual_shock + state_shock))
    ) +
    declare_inquiry(
      handler = function(data) {
        states |> transmute(
          state,
          inquiry = "mean_policy_support",
          estimand = state_mean
        )
      }
    ) +
    declare_estimator(handler = label_estimator(function(data) {
      model_fit <- glmer(
        formula = policy_support ~ HS + (1 | state),
        data = data,
        family = binomial(link = "logit")
      )
      post_stratification_helper(model_fit, data = data, group = state, weights = PS_weight)
    }),
    label = "Partial pooling",
    inquiry = "mean_policy_support")

  expect_error(simulate_design(declaration_15.4, sims = 1), NA)

})
