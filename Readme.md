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
 Do a `vagrant ssh` and install the following:
`sudo apt-get --no-install-recommends install virtualbox-guest-utils`
then get out and reboot with `vagrant halt && vagrant up`
Hopefully this will be fixed soon upstream:
https://bugs.launchpad.net/cloud-images/+bug/1565985

## Login into the VM and prepare the build env

Login into the VM with `vagrant ssh`

In this example we build packages for Ubuntu Trusty

At the first login prepare your env for trusty
```
sg sbuild
sbuild-update --keygen
mk-sbuild trusty
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
There are also stable branches like `stable/liberty` and `stable/mitaka`
In our use case we run openstack liberty so we will

```
git checkout stable/liberty
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

If you are building `horizon`, please check the special workaround to build `horizon` at https://wiki.ubuntu.com/OpenStack/CorePackages because this package is a bit special)


Start the build

```
sbuild-liberty -d trusty-amd64 -A ../build-area/cinder_7.0.2-0ubuntu1.dsc
```

If the build is successful you will find the new deb packages in the parent folder

`ls ../`
