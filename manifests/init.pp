# == Class: forge_server
#
# @summary
# A Puppet module to manage the Puppet Forge Server service
#
# @param package
#   Optional override of package name
# @param scl
#   Name of ruby scl environment, leave undef to use system ruby
# @param scl_install_timeout
#   If using ruby scl, the timeout in seconds to allow the gem installation to run
# @param scl_install_retries
#   If using ruby scl, the number of retries allowed if gem installation fails
# @param service_enable
#   Boolean if service should be enabled on boot
# @param service_ensure
#   Service ensure state
# @param service_refresh
#   Boolean if config changes and package changes should trigger service restart
# @param pidfile
#   Path to pidfile
# @param port
#   Port to bind to
# @param bind_host
#   IP or host to bind to
# @param daemonize
#   Boolean if should be daemonized
# @param module_directory
#   Directory of modules to serve, can be an array of directories
# @param http_proxy
#   Use proxyserver for http(s) connections
# @param proxy
#   Proxy requests to this upstream forge url
# @param cache_basedir
#   Path where to store proxied / cached modules
# @param log_dir
#   Path to log directory
# @param debug
#   Boolean to toggle debug
# @param forge_server_script
#   Name of the script which runs the forge server, depending on ruby version installed
# @param user
#   Name of the system user for forge-server
# @param user_homedir
#   Path to the system users home dir
# @param provider
#   Whether to use system ruby or puppet ruby
#
# @example
#
#  class { '::forge_server':
#    scl => 'ruby193'
#  }
#
# === Authors
#
# Johan Lyheden <johan.lyheden@unibet.com>
#
# === Copyright
#
# Copyright 2014 North Development AB
#
class forge_server (
  String[1]                  $package             = 'puppet-forge-server',
  String[1]                  $user                = 'forge',
  Stdlib::Unixpath           $user_homedir        = '/home/forge',
  Stdlib::UnixPath           $pidfile             = '/var/run/puppet-forge-server/forge-server.pid',
  Integer                    $port                = 8080,
  Stdlib::Host               $bind_host           = '127.0.0.1',
  Variant[Array[Stdlib::Unixpath], Stdlib::Unixpath] $module_directory    = '/var/lib/puppet-forge-server/modules',
  Optional                   $proxy               = undef,
  Stdlib::Unixpath           $cache_basedir       = '/var/lib/puppet-forge-server/cache',
  Stdlib::Unixpath           $log_dir             = '/var/log/puppet-forge-server',
  Enum['gem', 'puppet_gem']  $provider            = 'gem',
  Optional                   $http_proxy          = undef,
  Optional                   $scl                 = undef,
  Integer                    $scl_install_timeout = 300,
  Integer                    $scl_install_retries = 1,
  String[1]                  $forge_server_script = 'puppet-forge-server.ruby2.1',
  Boolean                    $service_enable      = true,
  Enum['running', 'stopped'] $service_ensure      = 'running',
  Boolean                    $service_refresh     = true,
  Boolean                    $daemonize           = true,
  Boolean                    $debug               = false,
) {

  if $scl {
    if $facts['os']['family'] != 'RedHat' {
      fail("SCL is not a valid configuration option for ${facts['os']['family']} systems")
    }
  }

  # contain class and ordering
  class { 'forge_server::user': }
  -> class { 'forge_server::package': }
  -> class { 'forge_server::config': }
  -> class { 'forge_server::files': }
  -> class { 'forge_server::service': }

  # optional refresh
  if $service_refresh {
    Class['forge_server::package'] ~> Class['forge_server::service']
    Class['forge_server::config'] ~> Class['forge_server::service']
  }

}
