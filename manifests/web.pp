# @summary
#   Setup Icinga Web 2 including a database backend for user settings.
#
# @param [Enum['mysql', 'pgsql']] db_type
#   What kind of database type to use.
#
# @param [Stdlib::Host] db_host
#   Database host to connect.
#
# @param [Optional[Stdlib::Port::Unprivileged]] db_port
#   Port to connect. Only affects for connection to remote database hosts.
#
# @param [String] db_name
#   Name of the database.
#
# @param [String] db_user
#   Database user name.
#
# @param [String] db_pass
#   Password to connect the database.
#
# @param [Boolean] manage_database
#   Create database.
#
# @param [Variant[Stdlib::Host, Array[String]]] api_host
#  Single or list of Icinga 2 API endpoints to connect.
#
# @param [String] api_user
#   Icinga 2 API user.
#
# @param [String] api_pass
#   Password to connect the Icinga 2 API.
#
# @param [Enum['mysql', 'pgsql']] backend_db_type
#   What kind of database type to use as IDO backend.
#
# @param [Stdlib::Host] backend_db_host
#   Database host to connect for the IDO backenend.
#
# @param [Optional[Stdlib::Port::Unprivileged]] backend_db_port
#   Port to connect the IDO backend. Only affects for connection to remote database hosts.
#
# @param [String] backend_db_name
#   Name of the IDO database backend.
#
# @param [String] backend_db_user
#   IDO database backend user name.
#
# @param [String] backend_db_pass
#   Pasword to connect the IDO backend.
#
class icinga::web(
  Enum['mysql', 'pgsql']                      $db_type          = 'mysql',
  Stdlib::Host                                $db_host          = 'localhost',
  Optional[Stdlib::Port::Unprivileged]        $db_port          = undef,
  String                                      $db_name          = 'icingaweb2',
  String                                      $db_user          = 'icingaweb2',
  String                                      $db_pass          = $icinga::params::web_db_pass,
  Boolean                                     $manage_database  = false,
  Variant[Stdlib::Host, Array[Stdlib::Host]]  $api_host         = 'localhost',
  String                                      $api_user         = 'icingaweb2',
  String                                      $api_pass         = $icinga::params::web_api_pass,
  Enum['mysql', 'pgsql']                      $backend_db_type  = 'mysql',
  Stdlib::Host                                $backend_db_host  = 'localhost',
  Optional[Stdlib::Port::Unprivileged]        $backend_db_port  = undef,
  String                                      $backend_db_name  = 'icinga2',
  String                                      $backend_db_user  = 'icinga2',
  String                                      $backend_db_pass  = $icinga::params::ido_db_pass,
) inherits icinga::params {

  unless $backend_db_port {
    $_backend_db_port = $backend_db_type ? {
      'pgsql' => 5432,
      default => 3306,
    }
  } else {
    $_backend_db_port = $backend_db_port
  }

  unless $db_port {
    $_db_port = $db_type ? {
      'pgsql' => 5432,
      default => 3306,
    }
  } else {
    $_db_port = $db_port
  }

  #
  # Platform
  #
  case $::osfamily {
    'redhat': {
      case $facts[os][release][major] {
        '6': {
          $php_globals = {
            php_version => 'rh-php70',
            rhscl_mode => 'rhscl',
          }
        }
        '7': {
          $php_globals = {
            php_version => 'rh-php73',
            rhscl_mode => 'rhscl',
          }
        }
        default: {
          $php_globals = {}
        }
      }
      $php_extensions = {
        mbstring => { ini_prefix => '20-' },
        json     => { ini_prefix => '20-' },
        ldap     => { ini_prefix => '20-' },
        gd       => { ini_prefix => '20-' },
        xml      => { ini_prefix => '20-' },
        intl     => { ini_prefix => '20-' },
        mysqlnd  => { ini_prefix => '20-' },
        pgsql    => { ini_prefix => '20-' },
      }
    } # RedHat

    'debian': {
      if $facts[os][distro][codename] == 'focal' {
        $php_globals = {
          php_version => '7.4',
        }
      } else {
        $php_globals = {}
      }
      $php_extensions = {
        mbstring => {},
        json     => {},
        ldap     => {},
        gd       => {},
        xml      => {},
        intl     => {},
        mysql    => {},
        pgsql    => {},
      }
    } # Debian

    default: {
      fail("'Your operatingsystem ${::operatingsystem} is not supported.'")
    }
  }

  #
  # PHP
  #
  class { '::php::globals':
    * => $php_globals,
  }

  class { '::php':
    ensure        => installed,
    manage_repos  => false,
    apache_config => false,
    fpm           => true,
    extensions    => $php_extensions,
    dev           => false,
    composer      => false,
    pear          => false,
    phpunit       => false,
    require       => Class['::php::globals'],
  }

  #
  # Apache
  #
  $manage_package = false

  Package['icingaweb2']
    -> Class['apache']

  package { 'icingaweb2':
    ensure => installed,
  }

  class { '::apache':
    default_mods => false,
    mpm_module   => 'worker',
  }

  apache::listen { '80': }

  $web_conf_user = $::apache::user

  include ::apache::mod::alias
  include ::apache::mod::status
  include ::apache::mod::dir
  include ::apache::mod::env
  include ::apache::mod::rewrite
  include ::apache::mod::proxy
  include ::apache::mod::proxy_fcgi
  include ::apache::mod::status
  include ::apache::mod::ssl

  apache::custom_config { 'icingaweb2':
    ensure        => present,
    source        => 'puppet:///modules/icingaweb2/examples/apache2/for-mod_proxy_fcgi.conf',
    verify_config => false,
    priority      => false,
  }

  #
  # Database
  #
  if $manage_database {
    class { '::icinga::web::database':
      db_type       => $db_type,
      db_name       => $db_name,
      db_user       => $db_user,
      db_pass       => $db_pass,
      web_instances => [ 'localhost' ],
      before        => Class['icingaweb2'],
    }
    $_db_host = 'localhost'
  } else {
    if $db_type != 'pgsql' {
      include ::mysql::client
    } else {
      include ::postgresql::client
    }
    $_db_host = $db_host
  }

  #
  # Icinga Web 2
  #
  class { 'icingaweb2':
    db_type        => $db_type,
    db_host        => $_db_host,
    db_port        => $_db_port,
    db_name        => $db_name,
    db_username    => $db_user,
    db_password    => $db_pass,
    import_schema  => true,
    config_backend => 'db',
    conf_user      => $web_conf_user,
    manage_package => $manage_package,
  }

  class { '::icingaweb2::module::monitoring':
    ido_type          => $backend_db_type,
    ido_host          => $backend_db_host,
    ido_port          => $_backend_db_port,
    ido_db_name       => $backend_db_name,
    ido_db_username   => $backend_db_user,
    ido_db_password   => $backend_db_pass,
  }

  any2array($api_host).each |Stdlib::Host $host| {
    ::icingaweb2::module::monitoring::commandtransport { $host:
      transport => 'api',
      host      => $host,
      username  => $api_user,
      password  => $api_pass,
    }
  }
}
