# `make` is expected to be called from the directory that contains
# this Makefile

# PKG_NAME is based on the name of the folder that holds this code
# (i.e. the name of the directory that contains 'src')
$(eval PKG_NAME := "vtg."$(shell Rscript -e "cat(basename(dirname(getwd())))"))

# These variables can be set as environment variables or as arguments to `make`
HOST ?= harbor2.vantage6.ai
IMAGE ?= algorithms/${PKG_NAME}
TAG ?= harukas
$(eval PWD := $(shell Rscript -e "cat(dirname(getwd()))"))

echo:
	@echo "package name: ${PKG_NAME}"
	@echo "  image name: ${IMAGE}"
	@echo "         tag: ${TAG}"
	@echo "         pwd: ${PWD}"
	@echo ""

build: install-deps document
	@echo "*** Building \"$(PKG_NAME)\" ***"
	@mkdir ../dist; cd ../dist; R CMD build ../src

install-deps: DESCRIPTION
	@echo "*** Installing dependencies for \"$(PKG_NAME)\" ***"
	@Rscript -e 'library(devtools)' -e 'install_deps(".")'

install: install-deps document
	@echo "*** Installing package \"$(PKG_NAME)\" ***"
	@R CMD INSTALL --no-multiarch --with-keep.source .

uninstall:
	@echo "*** Removing package \"$(PKG_NAME)\" ***"
	@R CMD REMOVE ${PKG_NAME}

DESCRIPTION: DESCRIPTION.tpl
	@echo "Generating \"DESCRIPTION\" from \"DESCRIPTION.tpl\""
	@echo "vantage6-Comment:" > DESCRIPTION
	@echo "    **************************************************" >> DESCRIPTION
	@echo "    * This file was generated from DESCRIPTION.tpl   *" >> DESCRIPTION
	@echo "    * Please don't modify it directly! Instead,      *" >> DESCRIPTION
	@echo "    * modify DESCRIPTION.tpl and run the following   *" >> DESCRIPTION
	@echo "    * command:                                       *" >> DESCRIPTION
	@echo "    *   make DESCRIPTION                             *" >> DESCRIPTION
	@echo "    **************************************************" >> DESCRIPTION
	@sed "s/{{PKG_NAME}}/${PKG_NAME}/g" DESCRIPTION.tpl >> DESCRIPTION

document:
	@Rscript -e "devtools::document(roclets=c('rd', 'collate', 'namespace', 'vignette'))"

docker: DESCRIPTION docker-build docker-push

docker-build:
	@echo "************************************************************************"
	@echo "* Building image '${IMAGE}:${TAG}' "
	@echo "************************************************************************"

	# The custom R base adds a few linux packages (openssl & xml2)
	# Additionally, it installs the R packages in 'install_base_packages.R'
	# to speedup building the image container this package's source.
	docker build \
	   -f ../docker/Dockerfile.custom-r-base \
	   -t custom-r-base \
	   ../

	# Build the docker image containing the local algorithm
	# docker build --no-cache -f docker/Dockerfile -t $IMAGE:$TAG -t $HOST/$IMAGE:$TAG .
	docker build \
	  -f ../docker/Dockerfile \
	   --build-arg PKG_NAME=${PKG_NAME} \
	  -t ${IMAGE}:${TAG} \
	  -t ${HOST}/${IMAGE}:${TAG} \
	  ../

docker-push: docker-build
	docker push ${HOST}/${IMAGE}:${TAG}

clean:
	rm DESCRIPTION
