# @summary Backup for Confluence Database
#
# Add backup script and configuration files to crontab
#
class profile_confluence {
# Recursively copy all backup files

  $config_files = [
    '/root/cron_scripts/confluence-backup.conf',
    '/root/cron_scripts/confluence-db.conf',
  ]

  $cron_files = ['/root/cron_scripts/wiki-backup.sh']

  file { '/var/tmp/testfile':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => 'This is a test file created using puppet.',
    ;
  }

  cron { 'confluence_backup':
    command     => '/root/cron_scripts/wiki-backup.sh',
    user        => 'root',
    hour        => 1,
    environment => ['SHELL=/bin/sh', 'MAILTO=meberger@illinois.edu'],
  }
}
