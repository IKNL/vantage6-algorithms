# The Dockerfile tells Docker how to construct the image with your algorithm.
# Once pushed to a repository, images can be downloaded and executed by the
# network hubs.
FROM harbor2.vantage6.ai/base/custom-r-base

# This is a placeholder that should be overloaded by invoking
# docker build with '--build-arg PKG_NAME=...'
ARG PKG_NAME='vtg.chisq'

LABEL maintainer="Hasan Alradhi <h.alradhi@iknl.nl>"

# Install federated chisq package
COPY ./models/chisq/src /usr/local/R/${PKG_NAME}/

WORKDIR /usr/local/R/${PKG_NAME}
RUN Rscript -e 'library(devtools)' -e 'install_deps(".")'
RUN R CMD INSTALL --no-multiarch --with-keep.source .

# Change directory to '/app’ and create files that will be
# used to mount input, output and database.
WORKDIR /app
RUN touch input.txt
RUN touch output.txt
RUN touch database

# Tell docker to execute `docker.wrapper()` when the image is run.
ENV PKG_NAME=${PKG_NAME}
CMD Rscript -e "vtg::docker.wrapper('$PKG_NAME')"

