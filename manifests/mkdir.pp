# == Define: forge_server::mkdir
#
# Helper define to create parent folders
#
define forge_server::mkdir () {

  if !defined(Exec["forge_server_mkdir_p_${title}"]) {
    exec { "forge_server_mkdir_p_${title}":
      command => "mkdir -p ${title}",
      creates => $title,
      path    => ['/bin', '/usr/bin']
    }
  }

}
