#'
#' Example on how to run the federated GLM using the MockClient.
#'

# datasets <- list(
#   read.csv('C:\\Users\\age2105.55108\\AppData\\Local\\vantage6\\node\\data\\data_user1.csv'),
#   read.csv('C:\\Users\\age2105.55108\\AppData\\Local\\vantage6\\node\\data\\data_user2.csv'),
#   read.csv('C:\\Users\\age2105.55108\\AppData\\Local\\vantage6\\node\\data\\data_user3.csv')
# )

# client <- vtg::MockClient$new(datasets, "vtg.glm")
# result <- vtg.glm::dglm(client, formula = num_awards ~ prog + math, family='poisson', tol=1e-08, maxit=25)