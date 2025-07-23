# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### :rocket: Add
- `install.sh` will configure and install the cronjob in crontab
### :pencil: Change
- absolute path to `.env` removed from `cron_check.sh` and `check_version.sh`. `install.sh` will inject the absolute path to `.env` in `cron_check.sh`.

## [0.0.1] 2025-07-23
### :rocket: Add
- MediaWiki Update Manager is on!

[Unreleased]: https://github.com/erremauro/mediawiki-backup/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/erremauro/mediawiki-backup/releases/tag/v0.0.1