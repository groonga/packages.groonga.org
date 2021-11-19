ARG FROM=centos:8
FROM ${FROM}

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  dnf install --enablerepo=powertools -y ${quiet} \
    gcc-c++ \
    make \
    rpm-build \
    rpmdevtools && \
  dnf clean ${quiet} all

RUN \
  sed \
    -i'' \
    -e 's/^%dist .*/%dist .module_el8.4.0+589+11e12751/' \
    /etc/rpm/macros.dist
