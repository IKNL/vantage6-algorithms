datasets <- list(
    read.csv("C://Users//age2105.55108//AppData//Local//vantage6//node//teststarter_n100_v2_source0.csv"),
    read.csv("C://Users//age2105.55108//AppData//Local//vantage6//node//teststarter_n100_v2_source2.csv")
)


client <- vtg::MockClient$new(datasets, pkgname='vtg.glm')


formula <- censor ~ e02_im_primary + site
types=list(
    e02_im_primary=list(type='factor',levels=c(1,2), ref=NULL),
    site=list(type='factor',levels=c(5,6,7,8,10), ref=NULL)
)

family<-'binomial'

organizations_to_include <- NULL

subset_rules <- NULL
subset_rules <- jsonlite::fromJSON("C://Users//age2105.55108//Downloads//subset_data_short.json")
# This .json contains 1 line:
# [{"subset": "site %in% c(5,6,7,8)"}]


results <- vtg.glm::dglm(client, formula=formula, types=types, family=family,
                         organizations_to_include=organizations_to_include, subset_rules=subset_rules)

