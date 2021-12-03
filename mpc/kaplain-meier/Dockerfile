# basic python3 image as base
FROM harbor2.vantage6.ai/algorithms/algorithm-base

# This is a placeholder that should be overloaded by invoking
# docker build with '--build-arg PKG_NAME=...'
ARG PKG_NAME="v6-kaplan-meier-py"

# install federated algorithm
RUN pip install tno.mpc.protocols.kaplan_meier

COPY . /app
RUN pip install /app

ENV PYTHONUNBUFFERED 1

# expose a port that may be used for communication to other algorithms via VPN. Default is 8888.
EXPOSE 8888

ENV PKG_NAME=${PKG_NAME}

# Tell docker to execute `docker_wrapper()` when the image is run.
CMD python -c "from vantage6.tools.docker_wrapper import docker_wrapper; docker_wrapper('${PKG_NAME}')"
