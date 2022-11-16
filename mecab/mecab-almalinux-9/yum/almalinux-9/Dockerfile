ARG FROM=almalinux:9
FROM ${FROM}

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  dnf install -y ${quiet} \
    gcc-c++ \
    make \
    rpm-build \
    rpmdevtools && \
  dnf clean ${quiet} all
