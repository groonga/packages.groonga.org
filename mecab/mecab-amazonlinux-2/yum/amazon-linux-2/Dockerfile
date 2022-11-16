ARG FROM=amazonlinux:2
FROM ${FROM}

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  yum install -y ${quiet} \
    gcc-c++ \
    make \
    rpm-build \
    rpmdevtools && \
  yum clean ${quiet} all
