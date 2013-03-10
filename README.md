# leiningen-win-installer

A standalone Windows Installer for Leiningen and Clojure.

Everything you need to get started with Clojure in a couple of clicks.

[Download](https://bitbucket.org/djpowell/leiningen-win-installer/downloads/leiningen-installer.exe)

## Details

The installer installs Leiningen and CURL to a per-user install
location, together with an embedded Java runtime including JDK
redistributables.

The LEIN_JAVA_CMD environment variable is set to point to the embedded
Java runtime, and lein.bat is added to the per-user PATH.

A blank profiles.clj file is created if none exists.

Start menu icons are created for opening a repl, and for editing
profiles.clj.


Produced using [InnoSetup
5.5.3](http://www.jrsoftware.org/isinfo.php).

Containing an embedded 32-bit install of [Java 1.7.0_17](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html),
and [CURL 7.28.1](http://www.paehl.com/open_source/?download=curl_728_1_ssl.zip).

## License

Copyright 2013 David Powell

Distributed under the Eclipse Public License, the same as Clojure.
