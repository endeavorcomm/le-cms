# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Changes all scripts to start with #!/usr/bin/env bash, for more flexability for any environment
- Fixes changelog versioning links
- Fixes copying files for a new certificate
- Fixes bash line on deploy-cert.sh
- Fixes acme redirect and 301 return lines when deploying an nginx site

## [2.1.3] - 2021-01-25

### Changed

- Fixes initial certificate file names when copying from CMS to servers, for consistency with version 2.0.0 breaking changes
- Removes 'sudo' from the beginning of the deploy hook command in the deploy-certificates.md documentation. This was causing $RENEWED_LINEAGE to be unavailable in the shell, and copying of renewed certs to remote hosts was failing
- Makes verify-http.sh commands more efficient

## [2.1.2] - 2020-11-24

### Added

- copy-cert.sh script. If a certificate gets renewed, but the files aren't properly copied to the remote servers, use this script to copy them. Instructions are in the 'Extras' section of the [README](./README.md).

### Changed

- Fixes copying of renewed certificate files

## [2.1.1] - 2020-11-05

### Added

- Official support for acme-dns

### Changed

- Document support for nginx
- Fixes changelog markdown links
- Clarifies verbiage in README.md
- Fixes nginx https site creation
- Fixes nginx http site redirect from http to https

## [2.0.0] - 2020-11-02

### Added

- Support NGINX web servers.

### Removed

- NGINX rate-limiting on new deployment instructions.

- '1' from the end of certificate filenames, when copied from your CMS. This will break future certificate renewal processes, so you must manually change the names of existing certifcate files on your servers which are hosting certificates.

## [1.0.0] - 2020-11-02

### Added

Everything!

[Unreleased]: https://github.com/endeavorcomm/le-cms/compare/v2.1.3...HEAD
[2.1.3]: https://github.com/endeavorcomm/le-cms/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/endeavorcomm/le-cms/compare/2.1.1...v2.1.2
[2.1.1]: https://github.com/endeavorcomm/le-cms/compare/2.0.0...2.1.1
[2.0.0]: https://github.com/endeavorcomm/le-cms/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/endeavorcomm/le-cms/releases/tag/1.0.0
