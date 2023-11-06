# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing to see here!

## [4.0.0] - 2023-11-06

### Added

- Support for hostgroups. Instead of using multiple hosts for deployment or renewal, you can define multiple hosts in a file and use the `-g` argument instead of `-h`. See [here](./deploy-certificates.md) for details.
- Support for configuration files when deploying new sites and certificates.
- Logic which no longer requires you to enter the certbot user's password for every host that you're deploying a TLS certificate to. Instead, it uses the ssh key that is already used for other purposes in this system.

### Changed

- Webserver graceful restart, from systemctl-based to native commands for nginx and apache2 (apachectl).
- Host cli option - from comma separated to comma with a trailing space separated, and multiple host IPs should be surrounded by single quotes (ex: -h '10.0.0.1, 10.0.0.2').

### Removed

- HTTP and HTTPS verifications in deploy-site.sh. These are nice, but if you have multiple webservers for this URL and certificate then the verification gives a false impression for the additional hosts. These checks are only going to test the webserver host which has the IP address from the DNS lookup. You can still use the verify-http.sh script to check, but opening the site in a browser is the best way to test the new site.

## [3.0.1] - 2021-08-19

### Changed

- Renew hook command is now inserted appropriately into the domain's renewal config file, instead of appended.

### Fixed

- Removes 'sudo' from renew hook command. Was causing an error and failing to copy certificates.

## [3.0.0] - 2021-08-06

### Changed

- All scripts to start with #!/usr/bin/env bash, for more flexibility for any environment
- Script's -h argument to comma separated format, instead of multiple -h args. (ex, -h 10.1.1.1,10.1.1.2)

### Fixed

- Changelog versioning links
- Copying files for a new certificate
- Bash line on deploy-cert.sh
- Acme redirect and 301 return lines when deploying an nginx site

## [2.1.3] - 2021-01-25

### Changed

- Makes verify-http.sh commands more efficient

### Fixed

- Initial certificate file names when copying from CMS to servers, for consistency with version 2.0.0 breaking changes

### Removed

- Removes 'sudo' from the beginning of the deploy hook command in the deploy-certificates.md documentation. This was causing $RENEWED_LINEAGE to be unavailable in the shell, and copying of renewed certs to remote hosts was failing

## [2.1.2] - 2020-11-24

### Added

- copy-cert.sh script. If a certificate gets renewed, but the files aren't properly copied to the remote servers, use this script to copy them. Instructions are in the 'Extras' section of the [README](./README.md).

### Fixed

- Copying of renewed certificate files

## [2.1.1] - 2020-11-05

### Added

- Official support for acme-dns

### Changed

- Document support for nginx
- Clarifies verbiage in README.md

### Fixed

- Changelog markdown links
- nginx https site creation
- nginx http site redirect from http to https

## [2.0.0] - 2020-11-02

### Added

- Support for NGINX web servers.

### Removed

- NGINX rate-limiting on new deployment instructions.

- '1' from the end of certificate filenames, when copied from your CMS. This will break future certificate renewal processes, so you must manually change the names of existing certifcate files on your servers which are hosting certificates.

## [1.0.0] - 2020-11-02

### Added

Everything!

[Unreleased]: https://github.com/endeavorcomm/le-cms/compare/v4.0.0...HEAD
[4.0.0]: https://github.com/endeavorcomm/le-cms/compare/v4.0.0...v3.0.1
[3.0.1]: https://github.com/endeavorcomm/le-cms/compare/v3.0.1...v3.0.0
[3.0.0]: https://github.com/endeavorcomm/le-cms/compare/v3.0.0...v2.1.3
[2.1.3]: https://github.com/endeavorcomm/le-cms/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/endeavorcomm/le-cms/compare/2.1.1...v2.1.2
[2.1.1]: https://github.com/endeavorcomm/le-cms/compare/2.0.0...2.1.1
[2.0.0]: https://github.com/endeavorcomm/le-cms/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/endeavorcomm/le-cms/releases/tag/1.0.0
