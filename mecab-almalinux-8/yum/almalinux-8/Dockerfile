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
    -e 's/^%dist .*/%dist .module_el8.6.0+3340+d764b636/' \
    /etc/rpm/macros.dist
