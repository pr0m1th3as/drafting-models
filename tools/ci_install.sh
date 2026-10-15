#!/bin/bash
# Install what the models need, in CI: the Octave packages their README's
# 'Depends:' lines name and the packages those depend on, from the Octave
# Packages index, after the system packages the index lists for them on
# this Ubuntu.  Run from the repository's root, inside the Octave image:
#
#   bash tools/ci_install.sh                every model
#   bash tools/ci_install.sh NAME ...       those models only
set -euo pipefail
S=""
if [ "$(id -u)" != 0 ]; then S=sudo; fi
$S apt-get update -qq

names="$*"
octave-cli --norc --no-history --eval "
  addpath ('tools');
  n = strsplit (strtrim ('$names'));
  requirements ('/tmp/req', n(! cellfun (@isempty, n)));"

system_packages=$(cat /tmp/req/system-packages.txt)
if [ -n "$system_packages" ]; then
  $S env DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC \
    apt-get install --yes -qq $system_packages > /dev/null
fi
while read -r p; do
  if [ -n "$p" ]; then
    octave-cli --norc --no-history --eval "pkg ('install', '-local', '$p')"
  fi
done < /tmp/req/octave-packages.txt
