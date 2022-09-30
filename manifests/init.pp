# @summary Backup for Confluence Database
#
# Add backup script and configuration files to crontab
#
class profile_confluence {
# Loop through backup configuration files
# Then copy over backup script

  $config_files = [
    '/root/cron_scripts/confluence-backup.conf',
    '/root/cron_scripts/confluence-db.conf',
  ]

  $cron_file = '/root/cron_scripts/wiki-backup.sh'

  $config_files.each |String $fname| {
    file {
      $fname :
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => "puppet:///modules/${module_name}/${fname}",
    }
  }
  file {
    $cron_file :
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0710',
      source => "puppet:///modules/${module_name}/${cron_file}",
  }

  cron { 'confluence_backup':
    command     => '/root/cron_scripts/wiki-backup.sh',
    user        => 'root',
    hour        => 2,
    minute      => 14,
    environment => ['SHELL=/bin/sh', 'MAILTO=meberger@illinois.edu'],
  }
}
