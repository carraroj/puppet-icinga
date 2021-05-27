class { '::icinga::repos':
  manage_epel => true,
}

class { '::icinga::server':
  ca            => true,
  config_server => true,
  global_zones  => [ 'global-templates', 'linux-commands', 'windows-commands' ],
}

class { '::icinga::ido':
  db_type         => 'pgsql',
  db_host         => 'localhost',
  manage_database => true,
}

class { '::icinga::web':
  backend_db_type => $icinga::ido::db_type,
  backend_db_host => $icinga::ido::db_host,
  db_type         => 'pgsql',
  db_host         => 'localhost',
  manage_database => true,
}
