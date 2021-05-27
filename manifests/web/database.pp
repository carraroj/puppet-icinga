# @summary
#   Setup Icinga Web 2 database for user settings.
#
# @param [Enum['mysql','pgsql']] db_type
#   What kind of database type to use.
#
# @param [Array[Stdlib::Host]] web_instances
#   List of Hosts to allow write access to the database. Usually an Icinga Web 2 instance.
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
class icinga::web::database(
  Enum['mysql','pgsql']  $db_type,
  Array[Stdlib::Host]    $web_instances,
  String                 $db_name = 'icingaweb2',
  String                 $db_user = 'icingaweb2',
  String                 $db_pass = $icinga::params::web_db_pass,
) inherits icinga::params {

  ::icinga::database { "${db_type}-${db_name}":
    db_type          => $db_type,
    db_name          => $db_name,
    db_user          => $db_user,
    db_pass          => $db_pass,
    access_instances => $web_instances,
    mysql_privileges => ['ALL'],
  }
}
