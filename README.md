
<h1 align="center">
  <br>
  <a href="https://vantage6.ai"><img src="https://github.com/IKNL/guidelines/blob/master/resources/logos/vantage6.png?raw=true" alt="vantage6" width="350"></a>
</h1>

<h3 align=center>Algorithms</h3>

------------------------------------

This repository is part of **vantage6**, our privacy preserving federated learning infrastructure for secure insight exchange. The aim of this repository is to collect algorithms, ensure quality and continues delivery in our Docker image registry (harbor2.vantage6.ai).

Algorithm documentation: [algorithms.vantage6.ai](https://algorithms.vantage6.ai)

## Algorithms

### Generalized Linear Model (GLM)

[![GLM Build](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml/badge.svg)](https://github.com/IKNL/vantage6-algorithms/actions/workflows/build-glm.yaml)

image: `harbor2.vantage6.ai/algorithms/glm:latest` <br>
test-image: `harbor2.vantage6.ai/algorithms/glm:[SHORT_COMMIT_HASH]`<br>
repository location: `/models/glm`<br>
langauge: `R`

------------------------

### ...

image: `...`<br>
test-image: `...`<br>
repository localtion: `/`<br>
langauge: `...`

------------------------
## Algorithm Submission Guidelines

Some general notes:

* Max characters per line: 80
* Use  when using Python and use
   when using R
* Every algorithm should have its own workflow file in `.github/workflows` to build it
* Non-production algorithms should be tagged with the short commit hash
* Document the algorithm in the `/docs` folder using ReST

_ We are developing a cookiecutter which helps you to kickstart your algorithm
project_

### R-algorithm
Style: [Tidyverse](https://style.tidyverse.org/)

Template: ... (TODO)

In R the package is installable (providing additional client side tooling and because we need to install it into the Docker image), therefore the package should have at least the following structure:
```bash
glm
│   .gitignore
│   project.Rproj
│   README.md
│   LICENSE
│
├───docker
│       Dockerfile
│
└───src
    │       DESCRIPTION
    │       DESCRIPTION.tpl
    │       Makefile
    │       NAMESPACE
    │
    ├───data
    │       ...
    │
    ├───man
    │       ...
    │
    └───R
            dglm.mock.R
            dglm.R
```
The `man` folder contains generated documentation. Make sure you document all your functions using [Roxygen](https://github.com/r-lib/roxygen2) style. `data` should contain some data that can be used to test the method using `dglm.mock.R`. The `DESCRIPTION` is generated from `DESCRIPTION.tpl` using the `build` instruction in the `makefile`. The `NAMESPACE` file should be there, just copy it from the template.

**Notes**
* Use `devtools` to create you package: [github](https://github.com/r-lib/devtools)
* You can add data by using the method `devtools::use_data(...)`
* If you add package data make sure you document it in `R/data.R`

### Python Algorithm

Style: [PEP 8](https://peps.python.org/pep-0008/)

Template: https://github.com/IKNL/v6-boilerplate-py

In python the algorithm needs to be installable into the Docker image. The minimal folder structure:
```bash
pkg_name
│   .gitignore
│   Dockerfile
│   LICENSE
│   README.md
│   requirements.txt
│   setup.py
│
└───v6-boilerplate-py
    │   example.py
    │   __init__.py
    │
    └───local
            data.csv
            input
            output
            token
```
