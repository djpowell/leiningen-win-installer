# leiningen-win-installer

A standalone Windows Installer for Leiningen and Clojure.

[Download](https://bitbucket.org/djpowell/leiningen-win-installer/downloads/leiningen-installer-beta1.exe)

## Status

This installer is currently a work in progress, but seem to work ok.

## Details

The installer installs Leiningen and CURL to a per-user install
location, and allows you to select a JDK to use with Leiningen.

The LEIN_JAVA_CMD environment variable is set to point to the selected
JDK, and lein.bat is added to the per-user PATH.

A blank profiles.clj file is created if none exists.

profiles.clj is updated to set :java-cmd to point to the selected JDK.

Start menu icons are created for opening a repl, and for editing
profiles.clj.


Produced using [InnoSetup
5.5.3](http://www.jrsoftware.org/isinfo.php).

## License

Copyright 2013 David Powell

Distributed under the Eclipse Public License, the same as Clojure.
