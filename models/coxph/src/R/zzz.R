.onLoad <- function(libname, pkgname) {
    # writeln()
    # writeln('vantage.basic .onLoad')
    # writeln(paste('  libname:', libname))
    # writeln(paste('  pkgname:', pkgname))
    # writeln()

    # fileName <- system.file('extdata', 'startup.message.txt', package=pkgname)
    # msg <- readChar(fileName, file.info(fileName)$size)
    # packageStartupMessage(msg)
}

.onAttach <- function(libname, pkgname) {
    # writeln('vantage.basic .onAttach')
    # writeln(paste('  libname:', libname))
    # writeln(paste('  pkgname:', pkgname))
    # writeln()
}

# FIXME: This is as close as I can get to a package-wide 'import x from y'
#        Anyone know a better way?
writeln <- vtg::writeln