#'
#' Example on how to run the federated GLM using the MockClient.
#'

# # Load package datasets
# data(example1, example2, example3)

# # Create a Mock client
# datasets <- list(example1, example2, example3)
# client <- vtg::MockClient$new(datasets, "vtg.glm")

# # Test the algorithm
# result <- vtg.glm::dglm(
#     client,
#     formula = num_awards ~ prog + math,
#     family = "poisson",
#     tol = 1e-08,
#     maxit = 25
# )
