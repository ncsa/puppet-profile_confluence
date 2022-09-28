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

  $cron_files = [ '/root/cron_scripts/wiki-backup.sh' ]

  #  file {
    #  $config_files:
    #  mode => '0440',
    #  ;
    #$cron_files:
    # mode   => '0660',
    #  ;
    file {"/var/tmp/testfile":
        ensure => "present",
        owner => "root",
        group => "root",
        mode => "664",
        content => "This is a test file created using puppet.".
}
    default:
      ensure => file,
      owner  => 'root',
      group => 'root',
      source  => "puppet:///modules/${module_name}",
      ;
  }

  cron { 'confluence_backup':
    command     => '/root/cron_scripts/wiki-backup.sh',
    user        => 'root',
    hour        => 1,
    environment => ['SHELL=/bin/sh', 'MAILTO=meberger@illinois.edu'],
  }
}


