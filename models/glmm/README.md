# This is a template repository!
You can create it to jumpstart your own algorithm for the [vantage6](https://github.com/IKNL/VANTAGE6) federated infrastructure.

## How to use this template?

You can use this repository as follows:
1. Make sure the R package `devtools` is installed.
2. Fork this repository or download the files as ZIP archive
3. Rename the folder containing the files to the name of your package. This is important, because the `Makefile` (located in `src/`) uses this folder name to infer your package name (and any docker images that follow from it). Alternatively, you can manually update the `Makefile`.
4. Add functions you want users to access to the `src/R` directory (as you normally would for any package).
5. Add functions you want to run on a node as you normally would, but prefix their names with `RPC_`.
6. Build your package
  * From RStudio: Menu -> Build -> Build All (or use the appropiate shortcut)
  * From the command line: run `make` in the directory that contains the `Makefile`.
7. Once satisfied, dockerize and upload your package by running `make docker` (check the `Makefile` for details). This requires you to be logged in to the docker (harbor) registry specified in the Makefile!

To make things easier for your users, you'll probably want to implement functions that run your federated functions. See `src/R/hello.R` and `src/R/RPC_hello.R` for examples.

The `R` package derived from this template uses a `Makefile` to build (see also https://www.r-bloggers.com/rstudio-and-makefiles-mind-your-options/). On Windows this might mean you have to install [RTools](https://cran.r-project.org/bin/windows/Rtools/), which includes `make` (through Cygwin). Alternatively, have a look at Windows Subsystem for Linux (WSL).

