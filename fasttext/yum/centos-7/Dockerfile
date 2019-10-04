FROM centos:7

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  yum update -y ${quiet} && \
  yum install -y ${quiet} epel-release && \
  yum groupinstall -y ${quiet} "Development Tools" && \
  yum install -y ${quiet} \
    cmake3 \
  yum clean ${quiet} all
