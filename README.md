# Naïve build/deploy/rollback scripts for docker containers

## Build and publish to the private registry
Build an image and publish it to the private registry

    ./build.rb git@github.com:1uptalent/someproject.git

This creates an image tagged as:

The tag is automatically generated from the last commit date, the last commit hash and the git user email.

## Deploy a container on some hosts
This command starts a new container based on the given image. Other containers based on the same repository (`some project`) are then stopped and removed.


The first parameter is a comma separated list of hosts. Connection will be stablished via ssh, so remember to `ssh-add` the relevant keys.

The second parameter is the full name of the image, as seen by the server.


## Rollback the last version

