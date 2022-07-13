# Clear the environment completely
rm(list = ls(all.names = TRUE))

# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg.basic)

setup.client <- function(local=TRUE) {
    username <- "admin@iknl.nl"
    password <- "zsDZ5IpCc0mzlL#2"
    collaboration_id_tcr <- 1
    collaboration_id_ucsc <- 2
    collaboration_id_test <- 3
    host <- 'https://api-test.distributedlearning.ai'
    api_path <- ''

    if (local) {
        vtg::writeln("Using LOCAL collaboration\n")
        collaboration_id <- collaboration_id_test
    } else {
        vtg::writeln("Using UCSC collaboration")
        collaboration_id <- collaboration_id_ucsc
    }

    client <- vtg::Client$new(host, api_path=api_path)
    client$authenticate(username, password)
    client$setCollaborationId(collaboration_id)

    return(client)
}

setup.mock.client <- function(splits=2) {
    data(SEER, package='vtg.basic')
    df <- SEER
    datasets <- list()

    for (k in 1:splits) {
        datasets[[k]] <- df[seq(k, nrow(df), by=splits), ]
    }

    client <- vtg::MockClient(datasets)
}

client <- setup.mock.client()
result <- hello(client, "Melle")

writeln()
writeln(rep('-', 80), sep='')
writeln('results:')
writeln(rep('-', 80), sep='')
print(result)