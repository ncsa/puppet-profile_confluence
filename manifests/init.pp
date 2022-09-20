# @summary Backup for Confluence Database
#
# Add backup script and configuration files to crontab
#
class profile_confluence {
  file { [ '/etc/confluence/', '/etc/confluence/backup' ]:
    ensure => directory,
  }

  File {
    group => 'wheel',
    owner => 'root',
    mode  => '0655',
    require => File['/etc/confluence/backup'],
    ensure  => 'file',
    replace => 'no',
  }

  file { '/etc/confluence/backup/wiki-backup.sh':
    source => 'puppet:///profile_confluence/files/wiki-backup.sh',
  }
  file { '/etc/confluence/backup/confluence-backup.conf':
    source => 'puppet:///profile_confluencefiles/confluence-backup.conf',
  }
  file { '/etc/confluence/backup/confluence-db.conf':
    source => 'puppet:///profile_confluence/files/confluence-db.conf',
  }

}
