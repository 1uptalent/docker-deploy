# Naïve build/deploy/rollback scripts for docker containers

## Build and publish to the private registry
Build an image and publish it to the private registry

    ./build.rb git@github.com:1uptalent/someproject.git

This creates an image tagged as:    localhost:9010/someproject:20140127_111245_250efbd_amuino

The tag is automatically generated from the last commit date, the last commit hash and the git user email.

## Deploy a container on some hosts
This command starts a new container based on the given image. Other containers based on the same repository (`some project`) are then stopped and removed.
    ./deploy.rb vagrant@localhost:2222 localhost:9010/someproject:20140127_111245_250efbd_amuino

The first parameter is a comma separated list of hosts. Connection will be stablished via ssh, so remember to `ssh-add` the relevant keys.

The second parameter is the full name of the image, as seen by the server.


## Rollback the last versionRollbacks are only a convenience/shortcut over manually looking up the previous version and using the `deploy.rb` script. It also does some housekeeping.
    ./rollback.rb vagrant@localhost:2222 rails-dockerRemoves the more recent tag (using the commit timestamp) from the registry and uses the previous one to do a new deploy.

