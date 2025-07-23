# MediaWiki Update Manager

## Configuration

* Rename `default.env` to `.env`
* Edit and save `.env`

### Variables

**MEDIAWIKI_PATH**: Specify the path to your mediawiki installation
**BACKUP_PATH**: Specify where the backup for your current installation should be saved. Both your mediawiki installation and sql dump will be created inside this path.
**HTTP_SERVICE**: specify the name of the http daemon that should be restarted after the update. `httpd` by default.
**UPDATE_LOG_FILE**: Specify which file should store the update logs.
**NOTIFY_EMAIL**: Specify the email address that will receive notifications of new updates available.

## Installation

To install the cron job for running timed version check:

```bash
./install.sh
```

## Version Check

To manually check if there is a new MediaWiki version available run:

```bash
./check_version.sh
```

## Update MediaWiki

To run an update of your MediaWiki, run:

```bash
./update.sh
```

It will check if a new MediaWiki version is available, create a backup in `$BACKUP_PATH` and run the update.

In case an error occur it will perform a rollback.

## Restore MediaWiki

To restore a previos backup, run:

```bash
./restore.sh
```

## Backup MediaWiki

You can backup your MediaWiki at any time by running:

```bash
./backup.sh
```