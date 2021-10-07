dglm.mock <- function(formula = num_awards ~ prog + math, types=NULL, dstar=NULL, family="poisson",tol= 1e-08,maxit=25) {

    datasets <- list(
        read.csv("C:\\Users\\FMa1805.36838\\OneDrive - IKNL\\Projects\\EURASIA\\DemoOrg-algo_testing-eurasia.csv"),
        read.csv("C:\\Users\\FMa1805.36838\\OneDrive - IKNL\\Projects\\EURASIA\\IKNL-algo_testing-eurasia.csv"),
        read.csv("C:\\Users\\FMa1805.36838\\OneDrive - IKNL\\Projects\\EURASIA\\MyStartup-algo_testing-eurasia.csv")
        #read.csv("C:\\Users\\FMa1805.36838\\OneDrive - IKNL\\Projects\\EURASIA\\data_user1.csv")
    )

    client <- vtg::MockClient$new(datasets, "vtg.glm")
    results <- vtg.glm::dglm(client, formula=formula, family=family, types=types, tol=tol, dstar=dstar)
}
types=list(sex=list(type='factor',levels=1:2,ref=NULL),
           site2=list(type='factor',levels=c(1:3,9),ref=NULL),
           end=list(type='factor',levels=1:5,ref=NULL),
           agecat2=list(type='factor',levels=1:5,ref=4),
           country1=list(type='factor',levels=c(1,2,4),ref=NULL))
#model <- dglm.mock(formula = d~end+agecat2+country1+offset(log(y)),dstar = "d_star",types=types, family = 'rs.poi',maxit=25,tol= 1e-08)
#model1 <- vtg.glm::dglm(client, formula = d~end+agecat2+country1+offset(log(y)),dstar = "d_star",types=types, family = 'rs.poi',maxit=25,tol= 1e-08)
#dglm.mock(formula = d~end+sex+age+site2+country1+offset(log(y)),dstar = "d_star",types=types, family = 'rs.poi',maxit=25,tol= 1e-08)
