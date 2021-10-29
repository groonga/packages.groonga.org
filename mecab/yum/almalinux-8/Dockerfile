ARG FROM=almalinux:8
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

RUN \
  sed \
    -i'' \
    -e 's/^%dist .*/%dist .module_el8.4.0+2532+b8928c02/' \
    /etc/rpm/macros.dist
