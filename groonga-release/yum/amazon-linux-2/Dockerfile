FROM amazonlinux:2

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  yum update -y ${quiet} && \
  yum install -y ${quiet} \
    rpm-build && \
  yum clean ${quiet} all
