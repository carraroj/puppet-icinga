class { 'postgresql::server':
  listen_addresses           => '*',
}

class { '::icinga::ido::database':
  ido_instances => ['192.168.5.13', '192.168.5.23'],
  db_type       => 'pgsql',
}

class { '::icinga::web::database':
  web_instances => ['192.168.5.13', '192.168.5.23'],
  db_type       => 'pgsql',
}
