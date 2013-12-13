## [0.4.1](https://github.com/fgrehm/vocker/compare/v0.4.0...v0.4.1) (December 13, 2013)

IMPROVEMENTS:

  - Make use of `https` when downloading Docker's gpg key [GH-19]

BUG FIXES:

  - Check for whether containers exists / are running now work across
    multiple Docker versions [GH-20]

## [0.4.0](https://github.com/fgrehm/vocker/compare/v0.3.3...v0.4.0) (November 8, 2013)

IMPROVEMENTS:

  - Make use of configured SSH user when adding to `docker` group [GH-17]
  - Support for data volumes [GH-13]
  - Support for exposing ports [GH-10]
  - Support for naming containers [GH-11]
  - Support for installing a specific Docker version [GH-9]
  - Improved checking for whether Docker is installed

BUG FIXES:

  - Make sure `curl` is installed on guest VMs [GH-15]

## [0.3.3](https://github.com/fgrehm/vocker/compare/v0.3.2...v0.3.3) (October 15, 2013)

  - Prevent `-r=true` from being appended multiple times to `/etc/init/docker.conf`

## [0.3.2](https://github.com/fgrehm/vocker/compare/v0.3.1...v0.3.2) (October 12, 2013)

  - Add support for additional parameters to be passed to the docker run cmd [GH-8](https://github.com/fgrehm/vocker/pull/8)
  - Add `vagrant` user to the docker group in order to avoid "sudoing" [GH-5](https://github.com/fgrehm/vocker/issues/5)
  - Attempt to start the docker service if it is not running

## [0.3.1](https://github.com/fgrehm/vocker/compare/v0.3.0...v0.3.1) (October 3, 2013)

  - Check if container is running before trying to restart
  - Configure automatic restart of containers regardless of Vagrant version

## [0.3.0](https://github.com/fgrehm/vocker/compare/v0.2.1...v0.3.0) (September 7, 2013)

  - Add support for Docker's `-dns` parameter

## [0.2.1](https://github.com/fgrehm/vocker/compare/v0.2.0...v0.2.1) (September 5, 2013)

  - Configure Docker to automatically restart previously running containers on boot [GH-4]

## [0.2.0](https://github.com/fgrehm/vocker/compare/v0.1.0...v0.2.0) (September 3, 2013)

  - Update installer for Docker 0.6 [GH-1]

## 0.1.0 (August 15, 2013)

  - Initial public release.
