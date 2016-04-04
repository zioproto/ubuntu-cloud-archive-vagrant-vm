#!/bin/bash

case $(id -u) in
0)
echo first: running as root
echo doing the root tasks...
add-apt-repository -s ppa:ubuntu-cloud-archive/tools
add-apt-repository -s cloud-archive:kilo
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get -y install cloud-archive-utils git-buildpackage debhelper sbuild

#Required for entropy to generate gpg keys
apt-get install rng-tools

#Required to build neutron
apt-get -y install dh-systemd openstack-pkg-tools python-setuptools python-pbr

# This script is done with this documentation
# https://wiki.ubuntu.com/SimpleSbuild

sudo adduser vagrant sbuild
echo "/home/vagrant/ubuntu/scratch  /scratch          none  rw,bind  0  0" | tee -a  /etc/schroot/sbuild/fstab
sudo -u vagrant -i $0  # script calling itself as the vagrant user
;;
*)
echo then: running as vagrant user
echo doing the vagrant user tasks
cat <<- EOF >  /home/vagrant/.sbuildrc

# Mail address where logs are sent to (mandatory, no default!)
\$mailto = 'zioproto@gmail.com';

# Name to use as override in .changes files for the Maintainer: field
# (mandatory, no default!).
\$maintainer_name='Saverio Proto <zioproto@gmail.com>';

# Default distribution to build.
\$distribution = "trusty";
# Build arch-all by default.
\$build_arch_all = 1;

# When to purge the build directory afterwards; possible values are "never",
# "successful", and "always".  "always" is the default. It can be helpful
# to preserve failing builds for debugging purposes.  Switch these comments
# if you want to preserve even successful builds, and then use
# "schroot -e --all-sessions" to clean them up manually.
\$purge_build_directory = 'successful';
\$purge_session = 'successful';
\$purge_build_deps = 'successful';
# \$purge_build_directory = 'never';
# \$purge_session = 'never';
# \$purge_build_deps = 'never';

# Directory for writing build logs to
\$log_dir="/home/vagrant/ubuntu/logs";

# don't remove this, Perl needs it:
1;

EOF

mkdir -p /home/vagrant/ubuntu/scratch
mkdir -p /home/vagrant/ubuntu/logs

cat <<- EOF >  /home/vagrant/.mk-sbuild.rc

SCHROOT_CONF_SUFFIX="source-root-users=root,sbuild,admin
source-root-groups=root,sbuild,admin
preserve-environment=true"
SKIP_UPDATES="1"
SKIP_PROPOSED="1"
# if you have e.g. apt-cacher-ng around
# DEBOOTSTRAP_PROXY=http://127.0.0.1:3142/

EOF

#
#sg sbuild
#sbuild-update --keygen
#mk-sbuild trusty

;;
esac
