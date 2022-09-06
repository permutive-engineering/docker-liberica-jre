# Glibc base image

This image compiles glibc for use with Alpine. 

In order to build and push this image, you must build and push an image for each target architecture
(`amd64` and `arm64`). Seeing as this is a compilation task, you must do this on a machine that uses
the target architecture, push the images to Github, then create a consoildated manifest. This readme
will guide you through how to do this.

## Log into the Github Docker Registry

First generate a Github personal access token with write permission to the package registry (you will
also have to grant the token SSO access for the `permutive-engineering` organisation.

Once you have you token use `docker login` to gain access to the registry. Use your Github username
as the username and the token you have just generated as the password:

```bash
docker login ghcr.io/permutive-engineering
```

## Build and Push the Architecture Specific Image

Use the command below while in this directory to build and push the image, substituting `<amd64|arm64>`
for your current architecture.

```bash
docker build . -t ghcr.io/permutive-engineering/permutive-glibc:<amd64|arm64>
docker push ghcr.io/permutive-engineering/permutive-glibc:<amd64|arm64>
```

> ⚠️ Make sure you have pushed images for both `amd64` and `arm64` architectures before proceeding to
> the next step.

## Create a Multi-Architecture Manifest

This final step will create a manifest that includes both images.

First, create a new `buildx` instance. If one already exists on your system, the first command below
will ensure it gets removed.

```bash
docker buildx rm glibc
docker buildx create --name glibc
docker buildx use glibc
docker buildx inspect --bootstrap
```

Then use the `imagetools` command to create and push a new maifest that contains each of the architecture
specific images:

```bash
docker buildx imagetools create -t ghcr.io/permutive-engineering/permutive-glibc:latest ghcr.io/permutive-engineering/permutive-glibc:amd64 ghcr.io/permutive-engineering/permutive-glibc:arm64
```

## Start using the new image

To force a new build, update
[the cache invalidator located at `.github/.cache_invalidator` in this repo](../.github/.cache_invalidator)
with a new value.
