ARG FROM=centos:8
FROM ${FROM}

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  dnf update -y ${quiet} && \
  dnf install -y ${quiet} \
    epel-release \
    'dnf-command(config-manager)' && \
  dnf config-manager --set-enabled PowerTools && \
  dnf groupinstall -y ${quiet} "Development Tools" && \
  dnf install -y ${quiet} \
    bzip2 \
    bzip2-devel \
    curl \
    file \
    gcc \
    gcc-c++ \
    git \
    make \
    openssl-devel \
    patch \
    readline-devel \
    wget \
    zlib-devel && \
  dnf clean ${quiet} all
