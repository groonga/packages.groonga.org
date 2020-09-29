ARG FROM=centos:8
FROM ${FROM}

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  dnf install --enablerepo=PowerTools -y ${quiet} \
    gcc-c++ \
    make \
    rpm-build \
    rpmdevtools && \
  dnf clean ${quiet} all
