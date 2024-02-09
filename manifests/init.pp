# @summary Prepare a server for running Confluence 
#
# Prepare a server for running Confluence
#
# @param db_name Database name
#
# @param db_user Authorized user to access the database
#
# @param db_password Password for $db_user to access the database
#
# @param confluence_home Confluence [shared] home, absolute filesystem path
#
# @param backup_dir Absolute path where backups should go
#
# @param backups_max_qty Keep this many backups
#
# @example
#   include profile_confluence
class profile_confluence (
  String  $db_name,
  String  $db_user,
  String  $db_password,
  String  $confluence_home,
  String  $backup_dir,
  Integer $backups_max_qty,
) {
  include lvm
  include profile_website

  $cron_params = {
    hour   => 4,
    minute => 4,
    user   => 'root',
  }

  # This seems to be the only way to interact with postgresql::globals
  # but install fails regardless
  # class { 'postgresql::globals':
  #   manage_dnf_module =>  true,
  #   manage_package_repo =>  true,
  #   version =>  '15',
  # }

  ### Postgres setup
  class { 'postgresql::server':
    backup_enable  => true,
    backup_options => {
      dir         => "${backup_dir}/postgres",
      db_user     => 'postgres_backup_user',
      db_password => $db_password,
      time        => [$cron_params[hour], $cron_params[minute]],
      manage_user => true,
      rotate      => $backups_max_qty,
    },
  }

  postgresql::server::database { $db_name :
    comment  => 'Confluence',
    encoding => 'UNICODE',
  }

  $pwdhash = postgresql::postgresql_password( $db_user, $db_password )
  postgresql::server::role { $db_user :
    password_hash => $pwdhash,
    createdb      => true,
    db            => $db_name,
  }

  postgresql::server::grant { $db_name :
    privilege => 'ALL',
    db        => $db_name,
    role      => $db_user,
  }

  ### Confluence Backups
  $confluence_backup = '/root/cron_scripts/confluence-backup.sh'
  file { $confluence_backup :
    ensure  => file,
    mode    => '0700',
    owner   => 'root',
    group   => '0',
    content => epp("profile_confluence/${confluence_backup}.epp", {
        confluence_home  => $confluence_home,
        backup_dir => "${backup_dir}/confluencehome",
        rotate     => $backups_max_qty,
      }
    ),
  }

  cron { 'confluence home backup':
    command => $confluence_backup,
    *       => $cron_params,
  }
}
