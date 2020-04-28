## How to install new gcc and development tools under CentOS 7

CentOS 7 is a very stable and conservative operating system. It offers us free enterprise-class operating system, which is compatible with Red Hat, but in many situations, we need a newer (not even a bleeding edge) tools from a trusted source not from an unknown third repository! Let’s say you are a developer and you need newer than GCC 4.8 (which is more than 5 years old and at present, we have stable GCC 8.x stable branch). There are repositories, which would surely break your system at one point even they do not break it at first installing a newer version of GNU GCC! There is a really easy and “official” way to have newer development software in CentOS 7 by using the [Software Collection – https://www.softwarecollections.org/en/scls/](https://www.softwarecollections.org/en/scls/)

We can say these packages are officially maintained by CentOS 7 team and as a whole Red Hat/CentOS officials and community developers! The collection aims at

1. Multiple version installed of the same components, you can have multiple GNU GCC installed without breaking your system or compiling manually. Not only GNU GCC, but you can also have PHP, Ruby, Python, famous databases like Mysql, MongoDB, PostgreSQL and many more
2. To have a newer version of the same components, you can have multiple version of GNU GCC – you can install with no worries of breaking your system GNU GCC 6 and 7

This article is to install GNU GCC 7 on CentOS 7 and we have a new one to install **GNU GCC 8** – [How to install GNU GCC 8 on CentOS 7](https://ahelpme.com/linux/centos7/how-to-install-gnu-gcc-8-on-centos-7/).

So here is how to install GNU GCC 7:

### STEP 1) Install the repository in your system

```bash
yum install centos-release-scl
```

Here is the output in our system:

```bash
[srv@local ~]# yum -y install centos-release-scl
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos.crazyfrogs.org
 * extras: centos.quelquesmots.fr
 * updates: centos.mirror.fr.planethoster.net
Resolving Dependencies
--> Running transaction check
---> Package centos-release-scl.noarch 0:2-2.el7.centos will be installed
--> Processing Dependency: centos-release-scl-rh for package: centos-release-scl-2-2.el7.centos.noarch
--> Running transaction check
---> Package centos-release-scl-rh.noarch 0:2-2.el7.centos will be installed
--> Finished Dependency Resolution
 
Dependencies Resolved
 
======================================================================================================================================================================
 Package                                          Arch                              Version                                   Repository                         Size
======================================================================================================================================================================
Installing:
 centos-release-scl                               noarch                            2-2.el7.centos                            extras                             12 k
Installing for dependencies:
 centos-release-scl-rh                            noarch                            2-2.el7.centos                            extras                             12 k
 
Transaction Summary
======================================================================================================================================================================
Install  1 Package (+1 Dependent package)
```

### STEP 2) Install the development tools and GNU GCC 7, which is part of the “devtools” package

```bash
yum install devtoolset-7-gcc-c++
```

Here is the output in our system:

```bash
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos.crazyfrogs.org
 * extras: centos.quelquesmots.fr
 * updates: centos.mirror.fr.planethoster.net     
Resolving Dependencies
--> Running transaction check
---> Package devtoolset-7-gcc-c++.x86_64 0:7.3.1-5.16.el7 will be installed
--> Processing Dependency: devtoolset-7-gcc = 7.3.1-5.16.el7 for package: devtoolset-7-gcc-c++-7.3.1-5.16.el7.x86_64
--> Processing Dependency: devtoolset-7-libstdc++-devel = 7.3.1-5.16.el7 for package: devtoolset-7-gcc-c++-7.3.1-5.16.el7.x86_64
--> Processing Dependency: devtoolset-7-runtime for package: devtoolset-7-gcc-c++-7.3.1-5.16.el7.x86_64
--> Processing Dependency: libmpc.so.3()(64bit) for package: devtoolset-7-gcc-c++-7.3.1-5.16.el7.x86_64
--> Processing Dependency: libmpfr.so.4()(64bit) for package: devtoolset-7-gcc-c++-7.3.1-5.16.el7.x86_64
--> Running transaction check
---> Package devtoolset-7-gcc.x86_64 0:7.3.1-5.16.el7 will be installed
--> Processing Dependency: devtoolset-7-binutils >= 2.22.52.0.1 for package: devtoolset-7-gcc-7.3.1-5.16.el7.x86_64
--> Processing Dependency: glibc-devel >= 2.2.90-12 for package: devtoolset-7-gcc-7.3.1-5.16.el7.x86_64
---> Package devtoolset-7-libstdc++-devel.x86_64 0:7.3.1-5.16.el7 will be installed
---> Package devtoolset-7-runtime.x86_64 0:7.1-4.el7 will be installed
--> Processing Dependency: scl-utils >= 20120927-11 for package: devtoolset-7-runtime-7.1-4.el7.x86_64
--> Processing Dependency: /usr/sbin/semanage for package: devtoolset-7-runtime-7.1-4.el7.x86_64
--> Processing Dependency: /usr/sbin/semanage for package: devtoolset-7-runtime-7.1-4.el7.x86_64
---> Package libmpc.x86_64 0:1.0.1-3.el7 will be installed
---> Package mpfr.x86_64 0:3.1.1-4.el7 will be installed
--> Running transaction check
---> Package devtoolset-7-binutils.x86_64 0:2.28-11.el7 will be installed
---> Package glibc-devel.x86_64 0:2.17-307.el7.1 will be installed
--> Processing Dependency: glibc-headers = 2.17-307.el7.1 for package: glibc-devel-2.17-307.el7.1.x86_64
--> Processing Dependency: glibc-headers for package: glibc-devel-2.17-307.el7.1.x86_64
---> Package policycoreutils-python.x86_64 0:2.5-34.el7 will be installed
--> Processing Dependency: setools-libs >= 3.3.8-4 for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: libsemanage-python >= 2.5-14 for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: audit-libs-python >= 2.1.3-4 for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: python-IPy for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: libqpol.so.1(VERS_1.4)(64bit) for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: libqpol.so.1(VERS_1.2)(64bit) for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: libcgroup for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: libapol.so.4(VERS_4.0)(64bit) for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: checkpolicy for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: libqpol.so.1()(64bit) for package: policycoreutils-python-2.5-34.el7.x86_64
--> Processing Dependency: libapol.so.4()(64bit) for package: policycoreutils-python-2.5-34.el7.x86_64
---> Package scl-utils.x86_64 0:20130529-19.el7 will be installed
--> Running transaction check
---> Package audit-libs-python.x86_64 0:2.8.5-4.el7 will be installed
---> Package checkpolicy.x86_64 0:2.5-8.el7 will be installed
---> Package glibc-headers.x86_64 0:2.17-307.el7.1 will be installed
--> Processing Dependency: kernel-headers >= 2.2.1 for package: glibc-headers-2.17-307.el7.1.x86_64
--> Processing Dependency: kernel-headers for package: glibc-headers-2.17-307.el7.1.x86_64
---> Package libcgroup.x86_64 0:0.41-21.el7 will be installed
---> Package libsemanage-python.x86_64 0:2.5-14.el7 will be installed
---> Package python-IPy.noarch 0:0.75-6.el7 will be installed
---> Package setools-libs.x86_64 0:3.3.8-4.el7 will be installed
--> Running transaction check
---> Package kernel-headers.x86_64 0:3.10.0-1127.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===================================================================================================================================
 Package                                    Arch                 Version                        Repository                    Size
===================================================================================================================================
Installing:
 devtoolset-7-gcc-c++                       x86_64               7.3.1-5.16.el7                 centos-sclo-rh                11 M
Installing for dependencies:
 audit-libs-python                          x86_64               2.8.5-4.el7                    base                          76 k
 checkpolicy                                x86_64               2.5-8.el7                      base                         295 k
 devtoolset-7-binutils                      x86_64               2.28-11.el7                    centos-sclo-rh               5.3 M
 devtoolset-7-gcc                           x86_64               7.3.1-5.16.el7                 centos-sclo-rh                29 M
 devtoolset-7-libstdc++-devel               x86_64               7.3.1-5.16.el7                 centos-sclo-rh               2.5 M
 devtoolset-7-runtime                       x86_64               7.1-4.el7                      centos-sclo-rh                20 k
 glibc-devel                                x86_64               2.17-307.el7.1                 base                         1.1 M
 glibc-headers                              x86_64               2.17-307.el7.1                 base                         689 k
 kernel-headers                             x86_64               3.10.0-1127.el7                base                         8.9 M
 libcgroup                                  x86_64               0.41-21.el7                    base                          66 k
 libmpc                                     x86_64               1.0.1-3.el7                    base                          51 k
 libsemanage-python                         x86_64               2.5-14.el7                     base                         113 k
 mpfr                                       x86_64               3.1.1-4.el7                    base                         203 k
 policycoreutils-python                     x86_64               2.5-34.el7                     base                         457 k
 python-IPy                                 noarch               0.75-6.el7                     base                          32 k
 scl-utils                                  x86_64               20130529-19.el7                base                          24 k
 setools-libs                               x86_64               3.3.8-4.el7                    base                         620 k

Transaction Summary
===================================================================================================================================
Install  1 Package (+17 Dependent packages)

Total download size: 61 M
Installed size: 145 M
Is this ok [y/d/N]: y
```

### STEP 3) Use the installed tools.

Because using such a package with multiple complex packages you must configure multiple environment and links to the versions you installed replacing the ones from your base system, but the package comes with a handy tool, which executing it will configure everything and you are ready to go!

```bash
scl enable devtoolset-7 bash
```

And you’ll be in a bash environment, which is configured for GNU GCC 7.

```bash
[srv@local ~]# scl enable devtoolset-7 bash
[srv@local ~]# which gcc
/opt/rh/devtoolset-7/root/usr/bin/gcc
[srv@local ~]# gcc --version
gcc (GCC) 7.3.1 20180303 (Red Hat 7.3.1-5)
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 
[root@srv ~]#
```

As long as you are in this bash shell (you do not type exit) your environment is configured to use GNU GCC 7 and you can use make, cmake to compile your projects with this newer version.

Before entering the devtoolset-7 bash shell, here is the error for the GNU GCC version:
