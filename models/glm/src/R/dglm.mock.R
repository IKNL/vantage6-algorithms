dglm.mock <- function(formula = num_awards ~ prog + math, types=NULL, dstar=NULL, family="poisson",tol= 1e-08,maxit=25) {

    datasets <- list(
        read.csv('/path/to/data1.csv'),
        read.csv('/path/to/data2.csv'),
        read.csv('/path/to/data3.csv')
    )

    client <- vtg::MockClient$new(datasets, "glm")
    results <- vtg.glm::dglm(client, formula=formula, family=family, types=types, tol=tol, dstar=dstar)
}

types=list(
    sex=list(type='factor',levels=1:2,ref=NULL),
    site2=list(type='factor',levels=c(1:3,9),ref=NULL),
    end=list(type='factor',levels=1:5,ref=NULL),
    agecat2=list(type='factor',levels=1:5,ref=4),
    country1=list(type='factor',levels=c(1,2,4),ref=NULL)
)

#model <- dglm.mock(formula = d~end+agecat2+country1+offset(log(y)),dstar = "d_star",types=types, family = 'rs.poi',maxit=25,tol= 1e-08)
#model1 <- vtg.glm::dglm(client, formula = d~end+agecat2+country1+offset(log(y)),dstar = "d_star",types=types, family = 'rs.poi',maxit=25,tol= 1e-08)
#dglm.mock(formula = d~end+sex+age+site2+country1+offset(log(y)),dstar = "d_star",types=types, family = 'rs.poi',maxit=25,tol= 1e-08)
