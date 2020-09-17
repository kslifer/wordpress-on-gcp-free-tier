# Wordpress Core
Download [the Wordpress distribution zip](https://wordpress.org/download/) from Wordpress, then place it in this directory and in your repo.

The build script will unpack and inject the distribution into the final Wordpress image.

There should only ever be one zip file in this directory, and it should be the same version of Wordpress as the parent Docker image that is being built from (as specified in the `FROM` statement in the Dockerfile).