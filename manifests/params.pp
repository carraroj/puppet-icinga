class icinga::params {
  $server_ticket_salt = extlib::cache_data('icinga_cache_data', 'server_ticket_salt', extlib::random_password(32))
  $ido_db_pass        = extlib::cache_data('icinga_cache_data', 'ido_db_pass', extlib::random_password(32))
  $web_db_pass        = extlib::cache_data('icinga_cache_data', 'web_db_pass', extlib::random_password(32))
  $web_api_pass       = extlib::cache_data('icinga_cache_data', 'web_api_pass', extlib::random_password(32))
}
