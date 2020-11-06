# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/endeavorcomm/le-cms/compare/2.0.0...HEAD
[2.1.1]: https://github.com/endeavorcomm/le-cms/compare/2.0.0...2.1.1
[2.0.0]: https://github.com/endeavorcomm/le-cms/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/endeavorcomm/le-cms/releases/tag/1.0.0