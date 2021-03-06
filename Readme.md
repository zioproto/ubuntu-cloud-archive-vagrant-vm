# Build a Ubuntu Cloud Archive package

This is a small guide tested on Ubuntu Xenial 16.04 to rebuild
packages from the Ubuntu Cloud Archive adding your own patches.

This is how I work to have patches merged upstream in Ubuntu

## Setup a VM with the necessary tools

Most of the steps are done by the Vagrant `bootstrap.sh` script. The scripts
automates what you find in the ubuntu documentation at https://wiki.ubuntu.com/SimpleSbuild

After cloning the repository start the ubuntu VM with `vagrant up`.

### Warning:
This `ubuntu/xenial64` is broken ! At the first boot provision will fail.

#### Workaround 1:

Do a `vagrant ssh` and install the following:
`sudo apt-get --no-install-recommends install virtualbox-guest-utils`
then get out and reboot with `vagrant halt && vagrant up`
Hopefully this will be fixed soon upstream:
https://bugs.launchpad.net/cloud-images/+bug/1565985

#### Workaround 2:

Install the vagrant-vbguest plugin that will take care of fixing the virtualbox vbguest

`vagrant plugin install vagrant-vbguest`

## Optional: instead of Vagrant run the VM on Openstack

Review the file `buildserver.yaml` to customize glance image, flavor and keypair. Now you can start the buildvm on openstack.

    source ~/openstack-rc.sh

    ansible-playbook buildserver.yaml

All the provisioning of the VM is done with cloud init. You can check the status if it with:

    openstack console log show ubuntu-build-packages

## Login into the VM and prepare the build env

Login into the VM with `vagrant ssh`

In this example we build packages for Ubuntu Xenial

At the first login prepare your env for xenial
```
sg sbuild
sbuild-update --keygen
mk-sbuild xenial
```

## Download upstream sources

Now for example let's rebuild the `cinder` package

The official ubuntu documentation is here:
https://wiki.ubuntu.com/OpenStack/CorePackages

```
debcheckout --git-track='*' cinder
```

You will now have a `cinder` folder that is a git
repository. An upstream branch contains the software version from upstream,
and the master branch contains the debian version.
There are also stable branches like `stable/mitaka` and `stable/newton`
In our use case we run openstack newton so we will

```
git checkout stable/newton
```

## Apply your own patch

New debian/ubuntu packages are built to hold the patches in a special folder:

```
cd cinder/
ls debian/patches/
```

Add your patch in `debian/patches/`
You can use the special folder `/vagrant` to copy the files from the host to
the VM (see Vagrant docs for details)

Add the namefile of your patch to `debian/patches/series`

Add your changes to the git index
```
git add debian/patches/*
```

Do not commit yet, we first update the debian changelog

## Update the debian changelog

Run this command to update the debian changelog

`dch -i`

Edit the changelog to look something like this:

```
cinder (2:7.0.2-0ubuntu2) UNRELEASED; urgency=medium

  * RBD: Delete snapshots if missing in the Ceph backend (LP: #1415905):
    - d/p/cinder-306610.patch: Apply patch from review 306610.

 -- Saverio Proto <saverio.proto@switch.ch> Mon, 29 Aug 2016 20:42:39 +0000
```

Now commit your changes into git, the `debcommit` tool will give to the git commit a description looking at the debian changelog

```
git add debian/changelog
debcommit
```

## Build the package

First of all we need to use `gbp buildpackage` to create the dsc file.

```
gbp buildpackage -S -us -uc
```

You will find the .dsc file in the `../build-area` folder

### Special case of building Horizon

If you are building `horizon`, please check the special workaround to build `horizon` at https://wiki.ubuntu.com/OpenStack/CorePackages because this package is a bit special).
If you are building a new release to generate the `horizon_<version>.orig-xstatic.tar.gz` you can use the script `./debian/rules refresh-xstatic` as described in the Readme file in the debian folder.

If you are rebuilding on top of a stable release, dont generate the xstatic file, you have to download it. This file is not in the pristine-tar branch.
You will not have the .dsc file in the  `../build-area` folder but in the `../` folder. Also you will need to download the orig tarballs.
Because you have two tarballs files you will have to use the `debuild` tool in the following way:
```
cd /home/ubuntu
wget https://launchpad.net/ubuntu/+archive/primary/+files/horizon_10.0.3.orig.tar.gz
wget https://launchpad.net/ubuntu/+archive/primary/+files/horizon_10.0.3.orig-xstatic.tar.gz
cd horizon
debuild -S -sa -us -uc
sbuild-newton -d xenial-amd64 -A ../horizon_10.0.3-0ubuntu2.dsc
```

To download the tarballs you have different options.
If you have the `deb-src` in `/etc/apt/source.list.d/<cloudarchive>` you will be
able to download the tarball using `apt source horizon`.

There also other `pull` commands available:
```
pull-lp-source horizon yakkety
pull-uca-source horizon newton
```

## Start the build

Once you have your dsc file you can start the build

```
sbuild-newton -d xenial-amd64 -A ../build-area/<filename>.dsc
```

If the build is successful you will find the new deb packages in the parent folder

`ls ../`

## Refresh a package after a new upstream release

In this example we see how we upgrade the package when the Nova team releases the nova version 14.0.5

```
debcheckout --git-track='*' nova
wget https://tarballs.openstack.org/nova/nova-14.0.5.tar.gz
cd nova
git checkout stable/newton
gbp import-orig --upstream-version=14.0.5 --debian-branch=stable/newton --merge --pristine-tar ../nova-14.0.5.tar.gz
```
You will have the upstream and tarballs branches

