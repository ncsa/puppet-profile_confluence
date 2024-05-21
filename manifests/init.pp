# @summary Prepare a server for running Confluence
#
# Prepare a server for running Jira Service Management
#
# @param db_name Database name
#
# @param db_user Authorized user to access the database
#
# @param db_password Password for $db_user to access the database
#
# @param confluence_home Jira [shared] home, absolute filesystem path
#
# @param backup_dir Absolute path where backups should go
#
# @param backups_max_qty Keep this many backups
#
# @param maintenance_allowed_ips Array of IPs allowed to access Confluence while in
#                                maintenance mode
# @param enable_cron_restart Boolean - Enable or disable the cronjob to
#        periodically restart the Confluence service.
#        Default: False
#
# @param cron_restart_params Hash, when to schedule the Confluence restart cron,
#        must be valid parameters to the Puppet Cron Resource
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
  Array   $maintenance_allowed_ips,
  Boolean $enable_cron_restart,
  Hash    $cron_restart_params,
) {
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
  }

  postgresql::server::database { $db_name :
    comment => 'Confluence',
    locale  => 'en_US.UTF-8',
    #encoding => 'UTF8',
  }

  $pwdhash = postgresql::postgresql_password( $db_user, $db_password )
  postgresql::server::role { $db_user :
    password_hash => $pwdhash,
    superuser     => true,
    db            => $db_name,
  }

  postgresql::server::grant { $db_name :
    privilege => 'ALL',
    db        => $db_name,
    role      => $db_user,
  }

  postgresql::server::schema { 'confluence':
    db => $db_name,
  }

  ### Maintenance setup
  # 503 downtime announcement
  $maint_html = '/var/www/html/maint.html'
  file { $maint_html:
    ensure => 'file',
    source => "puppet:///modules/${module_name}${maint_html}",
  }

  # IPs allowed to bypass maintenance mode
  $maint_dir = '/var/www/maintenance'
  $exceptions = "${maint_dir}/exceptions.map"
  file { $maint_dir:
    ensure => 'directory',
  }
  file { $exceptions:
    ensure  => 'file',
    content => epp("${module_name}/${exceptions}.epp", { 'cidr_list' => $maintenance_allowed_ips }),
  }

  # Enable scheduled service restarts
  if $enable_cron_restart {
    cron { 'Restart the confluence service periodically' :
      command => '/usr/bin/systemctl restart confluence',
      user    => root,
      *       => $cron_restart_params,
    }
  }

  # ### Backups
  # $bkup_script = '/root/cron_scripts/confluence-backup.sh'
  # file { $bkup_script :
  #   ensure  => file,
  #   mode    => '0700',
  #   owner   => 'root',
  #   group   => '0',
  #   content => epp("profile_confluence/${bkup_script}.epp", {
  #       jira_home  => $jira_home,
  #       backup_dir => "${backup_dir}/confluence",
  #       rotate     => $backups_max_qty,
  #     }
  #   ),
  # }

  # cron { 'jira home backup':
  #   command => $bkup_script,
  #   *       => $cron_params,
  # }
}
