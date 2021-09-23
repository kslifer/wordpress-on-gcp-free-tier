# Wordpress Core
Provide a URL to [the Wordpress distribution zip](https://wordpress.org/download/releases/) in the [download.txt](download.txt) file, and it will be fetched during the build process.

OR

Download it directly from Wordpress, then place it in this directory and in your repo.

The build script will unpack and inject the distribution into the final Wordpress image.

There should only ever be one zip file in this directory, and it should be the same version of Wordpress as the parent Docker image that is being built from (as specified in the `FROM` statement in the Dockerfile).