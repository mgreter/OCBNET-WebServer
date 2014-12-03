OCBNET-WebServer
================

Plack Webserver Implementation for Webmerge

INSTALL
=======

[![Build Status](https://travis-ci.org/mgreter/OCBNET-WebServer.svg?branch=master)](https://travis-ci.org/mgreter/OCBNET-WebServer)
[![Coverage Status](https://img.shields.io/coveralls/mgreter/OCBNET-WebServer.svg)](https://coveralls.io/r/mgreter/OCBNET-WebServer?branch=master)

Standard process for building & installing modules:

```
perl Build.PL
./Build installdeps
./Build
./Build test
./Build install
```

If you're on a platform (Windows) that doesn't require the "./" notation:

```
perl Build.PL
Build installdeps
Build
Build test
Build install
```

You need [Strawberry Perl](http://strawberryperl.com/) and
[GraphicsMagick](http://www.graphicsmagick.org/download.html) on
Windows.

Copyright
---------

(c) 2014 by [Marcel Greter](https://github.com/mgreter)
