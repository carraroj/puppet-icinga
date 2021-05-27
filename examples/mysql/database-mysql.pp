class { 'mysql::server':
  override_options => {
    'mysqld' => {
      'bind-address' => '0.0.0.0',
    },
  },
}

class { '::icinga::ido::database':
  ido_instances => ['192.168.5.13', '192.168.5.23'],
  db_type       => 'mysql',
}

class { '::icinga::web::database':
  web_instances => ['192.168.5.13', '192.168.5.23'],
  db_type       => 'mysql',
}
