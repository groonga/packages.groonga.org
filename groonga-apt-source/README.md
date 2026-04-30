### How to update

1. Download, sign, and upload groonga-apt-source packages

   ```console
   $ git clone --recursive git@github.com:groonga/packages.groonga.org.git
   $ cd packages.groonga.org/groonga-apt-source
   $ rake apt
   ```

2. Enable groonga-apt-source packages

   ```console
   $ cd ..
   $ rake apt
   ```
