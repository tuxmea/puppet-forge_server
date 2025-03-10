# == Class: forge_server::config
#
# Manages configuration files
#
class forge_server::config {

  # Scope config variables for templates
  $user                = $forge_server::user
  $pidfile             = $forge_server::pidfile
  $pid_dir             = dirname($forge_server::pidfile)
  $port                = $forge_server::port
  $bind_host           = $forge_server::bind_host
  $daemonize           = $forge_server::daemonize
  $module_directory    = $forge_server::module_directory
  $http_proxy          = $forge_server::http_proxy
  $proxy               = $forge_server::proxy
  $cache_basedir       = $forge_server::cache_basedir
  $log_dir             = $forge_server::log_dir
  $debug               = $forge_server::debug
  $scl                 = $forge_server::scl
  $provider            = $forge_server::provider
  $forge_server_script = $forge_server::forge_server_script

  file { '/etc/default/puppet-forge-server':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${facts['os']['family']}/puppet-forge-server.default.erb")
  }

  # On a systemd server create config file for tmpfiles.d
  case $facts['os']['name'] {
    'RedHat', 'CentOS', 'Fedora', 'Scientific', 'OracleLinux', 'SLC': {
      if versioncmp($facts['os']['release']['major'], '7') >= 0 {
        $unit_file_path = '/etc/systemd/system/puppet-forge-server.service'
        $unit_file_template = "${module_name}/puppet-forge-server.service.erb"
      }
    }
    'SLES': {
      if versioncmp($facts['os']['release']['major'], '12') >= 0 {
        $unit_file_path = '/usr/lib/systemd/system/puppet-forge-server.service'
        $unit_file_template = "${module_name}/${facts['os']['family']}/puppet-forge-server.service.erb"
      }
    }
    'Ubuntu': {
      if versioncmp($facts['os']['release']['major'], '15') >= 0 {
        $unit_file_path = '/etc/systemd/system/puppet-forge-server.service'
        $unit_file_template = "${module_name}/${facts['os']['family']}/puppet-forge-server.service.erb"
      }
    }
    default: {
    }
  }

  if $facts['service_provider'] == 'systemd' {
    file { '/usr/lib/tmpfiles.d/puppet-forge-server.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/puppet-forge-server.tmpfilesd.erb")
    }
    file { $unit_file_path:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => template($unit_file_template),
      notify  => Exec['forge_systemctl-daemon-reload'],
    }
    exec { 'forge_systemctl-daemon-reload':
      command     => 'systemctl daemon-reload',
      path        => '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin',
      refreshonly => true,
    }
  } else {
    file { '/etc/init.d/puppet-forge-server':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template("${module_name}/${facts['os']['family']}/puppet-forge-server.initd.erb")
    }
  }
}
