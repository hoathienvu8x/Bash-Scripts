---
title: "Build a rpm with docker"
link: "http://saule1508.github.io/build-rpm-with-docker/"
publish: "2019-02-14"
author: "Pierre Timmermans"
---

In my current company I had to build some rpm's in order to distribute my scripts to the servers we are selling to the customers. Since I am leaving this company I wanted to document this way of working as it might be useful for me in the future...
<!--more-->

I am using jenkins to kick-off the job, basically jenkins is used to checkout the code then launch a script that will:
* First create a docker image containings the necessary packages for rpmbuild and my sources;
* Secondly run a container based on this image and start a script to create the rpm;
* the created rpm is copied on a bind volume so that jenkins can recuperate it.

jenkins sets the variables BUILD_NUMBER and WORKSPACE. I use BUILD_NUMBER as the release part of the rpm version, but if the build is running on branch develop, then I use "snapshot" instead. The first part of the version is always read from a file called version.txt stored at the root of the git repo. 

So, assuming the file version.txt contains 7.0.0 :

* building on branch develop -> the rpm will be called mypackage-7.0.0-snapshot-noarch.rpm
* building on another branch -> the rpm will be called mypackage-7.0.0-xxx-noarch.rpm, where xxx is BUILD_NUMBER

Here is how the main script looks like. This script is called from jenkins with a parameter that is the git branch.

``` bash

PACKAGE_TO_BUILD=mypackage

help(){
 echo "$0 -b <branch> where branch is git branch. When branch is develop, snapshot will be added to the version"
 exit 1
}

while getopts b:h ARG
do
   case $ARG in
      b ) BRANCH=${OPTARG};;
      h ) help ;;
      * ) echo "invalid parameter"
          help
          exit;;
   esac
done
VERSION=$(cat version.txt)
if [ $BRANCH == "develop" ] ; then
  BUILD_NUMBER="snapshot"
fi
# directory where the rpm will be stored
if [ -d artifacts ] ; then
 sudo rm -rf artifacts
fi
mkdir artifacts
chmod 777 artifacts

# First build a docker image that contains the sources and necessary packages for rpmbuild
docker build -t ${PACKAGE_TO_BUILD}-build .

# then run the docker image
if [ -z $WORKSPACE ] ; then
  # we are not being called from within jenkins
  WORKSPACE=$(pwd)
fi
docker run --rm=true -v ${WORKSPACE}/artifacts:/artifacts -e BUILD_NUMBER=${BUILD_NUMBER} -e VERSION=$VERSION --user rpmbuild ${PACKAGE_TO_BUILD}-build /home/rpmbuild/build_rpm.bash

```

The Dockerfile contains something similar to the one below. Since jenkins has done the checkout of the repository, everything needed is in the docker build context (i.e. my sources are readily available to be added in the image, see the COPY instructions)

```bash
FROM centos:centos7
MAINTAINER ptim007@yahoo.com
RUN yum -y install rpm-build redhat-rpm-config make gcc git vi tar unzip rpmlint && yum clean all
RUN useradd rpmbuild -u 5002 -g users -p rpmbuild
# here I add everything I need to make the rpm: sources, the build script, etc...all of that was checkout from git by jenkins.
COPY build/build_rpm.bash /home/rpmbuild/build_rpm.bash
COPY build/mypackage.spec /home/rpmbuild/mypackage.spec
COPY version.txt /home/rpmbuild/versions.txt
COPY src /home/rpmbuild/src
USER rpmbuild
ENV HOME /home/rpmbuild
WORKDIR /home/rpmbuild
RUN mkdir -p /home/rpmbuild/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN echo '%_topdir %{getenv:HOME}/rpmbuild' > /home/rpmbuild/.rpmmacros
```

The build_rpm.bash copied inside the docker image is the script executed in the container (see docker run command). It looks like that

```bash
#!/bin/bash

PACKAGE=mypackage

if [ -z $BUILD_NUMBER ] ; then
 echo BUILD_NUMBER is not know, it is normally given by jenkins
 exit 1
fi
RELEASE=$BUILD_NUMBER
if [ -z $VERSION ] ; then
  echo VERSION is not set via parameter neither via ENV, will use version.txt
  VERSION=`cat version.txt`
fi

cd /home/rpmbuild
if [ ! -f ./${MYPACKAGE}.spec ] ; then
 echo Sorry, can not find rpm spec file 
 exit 1
fi
cp ${MYPACKAGE}.spec $HOME/rpmbuild/SPECS
# here I patch the spec file to feed it with the version and the release and the date
sed -i -e "s/##VERSION##/${VERSION}/" -e "s/##RELEASE##/${RELEASE}/" /home/rpmbuild/rpmbuild/SPECS/${PACKNAME}.spec
sed -i -e "s/##DATE##/`date +\"%a %b %d %Y\"`/" /home/rpmbuild/rpmbuild/SPECS/${PACKNAME}.spec

# prepare a tar.gz file with the sources and copy it  to the SOURCES directory
...
tar -zcf ${PACKAGE}-${VERSION}-${RELEASE}.tar.gz ./src
cp ${PACKAGE}-${VERSION}-${RELEASE}.tar.gz $HOME/rpmbuild/SOURCES/


# then execute the rpmbuild command
cd $HOME/rpmbuild
rpmbuild -ba --define "_buildnr ${BUILD_NUMBER}" --define "_myversion $VERSION" ./SPECS/${PACKAGE}.spec
# copy the rpms to the artifact directory, for jenkins.
if [[ -d /artifacts ]] ; then
 cp ./RPMS/noarch/${PACKAGE}*.rpm /artifacts/
fi
 
```

For reference (and my future usage !), here is how a spec file of one of my rpm looks like:

```
Name: mypackage
Version: ##VERSION##
Release: ##RELEASE##
Summary: mypackage scripts

Group: Any
License: GPL
URL: www.XXXX.com
Source0: mypackage_%{version}-%{release}.tar.gz
BuildArch: noarch
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
Installation package for mypackage

%prep
%setup -q -n mypackage_%{version}-%{release}

%install
rm -rf %{buildroot}
install -d $RPM_BUILD_ROOT/opt/mypackage
cp -r src  $RPM_BUILD_ROOT/opt/mypackage

%clean
rm -rf %{buildroot}

%post
echo " "
echo "install done, you can execute the install.sh scripts"

%files
%defattr(754,oracle,oinstall,754)
%dir /opt/mypackage
/opt/mypackage

%attr(750,oracle,oinstall) /opt/mypackage/install.sh
... etc (list the files here)

%changelog
* ##DATE## mypackage - %{version} %{release}
- Automatic build
```
