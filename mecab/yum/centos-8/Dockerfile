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

RUN \
  sed \
    -i'' \
    -e 's/^%dist .*/%dist .module_el8.2.0+493+63b41e36/' \
    /etc/rpm/macros.dist
