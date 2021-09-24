# Wordpress Plugins
Provide public URLs to [the plugin zip files](https://wordpress.org/plugins/) in the [download.txt](download.txt) file, and they will be fetched during the build process.

OR

Download them directly from Wordpress (or other source), then place them in this directory and in your repo.

The build script will unpack and inject them into the final Wordpress image.

It assumes that each zip file contains a unique plugin; avoid multiple versions of the same plugin.