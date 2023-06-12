---
title: "How to build .DEB packages through Docker"
link: "https://collabnix.com/how-to-build-deb-packages-through-docker/"
author: "Ajeet Singh Raina"
publish: "31st October 2015"
---

Building `.DEB` package is still a daunting process. It involves a series of
compiling, linking and building the source packages. Compiling tuns your
source code into object code.Linking combines your object code with libraries
into a raw executable whereas building is the sequence composed of compiling
and linking, with possibly other tasks such as installer creation.

You start with setting up build process, linking the object code with libraries
and then series of steps to build `.DEB` packages. It involves complexity and
series of debugging to reach the end point of creating `.DEB` packages. Last
week I started looking at making the developer’s work more easy. Why not
use Docker?  Let me share how easy is it get `.DEB` packages built up. Here
we go:

I picked up nagios as I have a pretty good understanding on Nagios tool.

My Dockerfile looked very similar to the below:

![](https://collabnix.com/wp-content/uploads/2015/10/Docker_DEB.png)

File: **build.sh**

The file `build.sh` helps you to build the container through Docker file.
Hope this is placed under the parent nagios/ directory.

![](https://collabnix.com/wp-content/uploads/2015/10/Docker_DEB2.jpg)

Once `.deb` is created through Dockerfile successfully, you might be interested
to copy it to the host machine and henceafter removing the container. This
file might help you with this.

File: **extractdeb.sh**

![](https://collabnix.com/wp-content/uploads/2015/10/Dock_1.jpg)

File: **resource/configure.sh**

The `configure.sh` provides all the necessary option for supplying the required
parameter for nagios to pick and stay on the filesystem as shown below:

![](https://collabnix.com/wp-content/uploads/2015/10/Docker_DEB4.jpg)

That’s it. Just run the below commands in sequence and you are ready to
build `.DEB` package in a single shot:

```bash
cd ajeetraina/nagios
./build.sh
./extractdeb.sh
```

Hope you enjoyed the post. Do reach out to me if you have further ideas
and suggestions.
