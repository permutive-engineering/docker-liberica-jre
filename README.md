# docker-liberica-jre

## Introduction

Provides base Java Docker images using Alpine, [Liberica] an glibc.

Builds run daily, but updates to images are only pushed if Apline or the JVM is updated.

This repository is derived from the images defined in the
[Liberica public repo](https://github.com/bell-sw/Liberica) licenced under GPL 2.0.

## Images

This repo currently maintains builds for versions 11 and 17 of the JRE. The image name/tags are as follows:

```
ghcr.io/permutive-engineering/permutive-jre-liberica:17
```

```
ghcr.io/permutive-engineering/permutive-jre-liberica:11
```

In addition to the major versions, builds of each JDK (shipped as a JRE) are maintained individually. Follow the links below to see which are available:

- [JRE 17](https://api.bell-sw.com/v1/liberica/releases?version-feature=17&bitness=64&os=linux&arch=x86&package-type=tar.gz&bundle-type=jre)
- [JRE 11](https://api.bell-sw.com/v1/liberica/releases?version-feature=11&bitness=64&os=linux&arch=x86&package-type=tar.gz&bundle-type=jre)

For all available image versions see the
[Github Packages listing for this repo](https://github.com/permutive-engineering/docker-liberica-jre/pkgs/container/permutive-jre-liberica/versions).

## Why Does Permutive Maintain their Own Java Images?

For a number of interconnected reasons:

- We want to use Alpine Linux as our base image because
  - It is small, so less to pull from the registry on startup
  - It has fewer binaries in the base image, so a smaller attack surface than Debian
- Alpine Linux ships with Musl libc
  - This has been known to cause runtime failures with Java libraries that use native C bindings, such as gRPC and Snappy. The compatibility packages
    `libc6-compat` and `gcompat` have proven to be unreliable
  - Using the "real" glibc has proven to be the best approach
- [Liberica] is the only JRE that runs on Alpine Linux using glibc
  - They only build a new image when a new JVM is released _not_ when the base image is updated, meaning important security updates could be missed 
  - Azul publish JREs with an Alpine Linux base, but at time of writing these are built against Musl, so won't work under glibc

[Liberica]: https://bell-sw.com/pages/downloads/
