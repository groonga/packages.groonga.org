#!/bin/bash

set -eu

base_dir=$(dirname $0)
cp -a "${base_dir}/LICENSE.Fedora" rpmbuild/SOURCES/
cp -a "${base_dir}/terms-and-conditions-for-IFS-J.html" rpmbuild/SOURCES/
