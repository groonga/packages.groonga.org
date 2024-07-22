### Why We Mirror Apache Arrow

Groonga depends on Apache Arrow. However, the official Apache Arrow repository has been unstable at times, causing issues for Groonga users. To resolve this situation, we have been providing a mirrored version for Groonga users.

#### Note

We would like to stop mirroring the Apache Arrow repository.
Therefore, we intend to stop mirroring once the Apache Arrow repository is stable.


### How to version up

1. Update Apache Arrow version and release data in Rakefile

   ```console
   $ git clone --recursive git@github.com:groonga/packages.groonga.org.git
   $ editor packages.groonga.org/apache-arrow/Rakefile
   ```

   For example, We update Rakefile as below

   ```diff
   class ApacheArrowPackageTask < PackagesGroongaOrgPackageTask
	 def initialize
   -    super("apache-arrow", "7.0.0", Time.new(2022, 2, 3))
   +    super("apache-arrow", "8.0.0", Time.new(2022, 5, 6))
	 end
   ```

2. Downlod Apache Arrow packages

   ```console
   $ cd packages.groonga.org/apache-arrow
   $ rake apt yum
   ```

3. Upload Apache Arrow packages to packages.groonga.org

   ```console
   $ cd ..
   $ rake apt yum
   ```
