FROM python:3.11.7-slim-bookworm AS builder

ARG BUILD_DEPS="\
    docker \
    gcc \
    libc-dev \
    libffi-dev \
    make \
    musl-dev \
    openssh-client \
    "

RUN apt-get update && \
    apt-get install --no-install-recommends -y ${BUILD_DEPS} && \
    rm -rf /var/lib/apt/lists/*

COPY Pipfile* .
RUN pip install --no-cache-dir pipenv && \
    pipenv install --deploy --system

FROM python:3.11.7-slim-bookworm AS runtime

LABEL "maintainer"="Evgenii Vasilenko <gmrnsk@gmail.com>"
LABEL "repository"="https://github.com/gofrolist/molecule-action"
LABEL "com.github.actions.name"="molecule"
LABEL "com.github.actions.description"="Run Ansible Molecule"
LABEL "com.github.actions.icon"="upload"
LABEL "com.github.actions.color"="green"

COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ansible* \
    /usr/local/bin/molecule \
    /usr/local/bin/pre-commit* \
    /usr/local/bin/yamllint \
    /usr/local/bin/

ARG PACKAGES="\
    docker.io \
    git \
    openssh-client \
    podman \
    rsync \
    tini \
    "

RUN apt-get update && \
    apt-get install --no-install-recommends -y ${PACKAGES} && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD cd ${INPUT_MOLECULE_WORKING_DIR}; molecule ${INPUT_MOLECULE_OPTIONS} ${INPUT_MOLECULE_COMMAND} ${INPUT_MOLECULE_ARGS}
