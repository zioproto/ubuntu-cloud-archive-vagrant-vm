# Build a Ubuntu Cloud Archive package

This is a small guide tested on Ubuntu Trusty 14.04 to rebuild
packages from the Ubuntu Cloud Archive adding your own patches.

This is probably not the right way to build Ubuntu packages, but
it worked for me :)

## Setup a VM with the necessary tools

Most of the steps are done by the Vagrant `bootstrap.sh` script.
After cloning the repository start the ubuntu VM with `vagrant up`.

## Login into the VM and prepare the build env

Login into the VM with `vagrant ssh`

At the first login prepare your env for trusty
```
sg sbuild
sbuild-update --keygen
mk-sbuild trusty
```

## Download upstream sources

Now for example let's rebuild the `cinder` package

```
apt-get source --download-only cinder-volume
gbp import-dsc cinder_2015.1.3-0ubuntu1.dsc
```

After these two command you will have a `cinder` folder that is a git
repository. An upstream branch contains the software version from upstream,
and the master branch contains the debian version.

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

Commit your changes
```
git add debian/patches/*
git commit -m "Commit msg that makes sense"
```

## Update the debian changelog

Run this command to update the debian changelog

`gbp dch`

Eventually edit `debian/changelog` so that your package will have a proper
version name. In my cinder example the changelog looks like:
```
cinder (1:2015.1.3-0ubuntu1+switch0) trusty-kilo; urgency=medium

  * RBD: Make snapshot_delete more robust

 -- Saverio Proto <saverio.proto@switch.ch>  Thu, 31 Mar 2016 20:18:06 +0000

cinder (1:2015.1.3-0ubuntu1) trusty-kilo; urgency=medium

  * New upstream stable release (LP: #1559215).

 -- James Page <james.page@ubuntu.com>  Sat, 19 Mar 2016 08:54:31 +0000

```

Now commit your changes to the changelog

```
git add debian/changelog
git commit --amend
```

## Build the package

Start the build

```
sbuild-kilo -d trusty-amd64
```

If the build is successful you will find the new deb packages in the parent folder

`ls ../`
