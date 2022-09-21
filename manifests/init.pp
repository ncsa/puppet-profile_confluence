# @summary Backup for Confluence Database
#
# Add backup script and configuration files to crontab
#
class profile_confluence {
# Recursively copy all backup files

  file { '/root/cron_scripts/':
    ensure  => directory,
    source  => "puppet:///modules/${module_name}/root/cron_scripts/",
    recurse => true,
  }

  cron { 'confluence_backup':
    command     => '/root/cron_scripts/wiki-backup.sh',
    user        => 'root',
    hour        => 1,
    environment => ['SHELL=/bin/sh', 'MAILTO=meberger@illinois.edu'],
  }
}
