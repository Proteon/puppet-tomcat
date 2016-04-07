# ==== Resource: tomcat::jndi::database::mysql
#
# This resource adds a mysql database connection to the jndi resources. It will also create the database with the provided
# parameters if not present or defined elsewhere.
#
# === Parameters
#
# Document parameters here.
#
# [*database*] The name of the database to create the resource for.
# [*username*] The username of the database.
# [*password*] The password of the database.
# [*resource_name*] The name of the jndi resource (defaults to 'jdbc/MysqlPool').
# [*instance*] The name of the instance we're creating the resource on (defaults to $name).
# [*host*] The host where the database runs on (defaults to 'localhost').
# [*driver*] The driver class to use (defaults to 'com.mysql.jdbc.Driver').
# [*use_unicode*] Use unicode (defaults to true).
# [*character_encoding*] Character encoding to use (defaults to 'UTF-8').
# [*fast_date_parsing*] Use fast date parsing (defaults to false).
# [*initial_size*] Initial pool size (defaults to 4).
# [*max_active*] Max active connections (defaults to 8).
# [*max_idle*] Minimal active connections (defaults to 4).
# [*min_evictable_time*] Minimum time in miliseconds a connection should be idle before it can be evicted (defaults to 600000).
# [*eviction_interval*] Interval in miliseconds at which is being checked for idle connections (defaults to 60000).
# [*jmx_enabled*] Enable jmx for the connection pool (defaults to true),
# [*validation_query*] The query to use to check if a connection is still valid (defaults to 'SELECT 1'),
#
# === Variables
#
# === Examples
#
#  tomcat::jndi::database::mysql { 'tomcat_01':
#   database        => 'my_mysql_db',
#   username        => 'my_user',
#   password        => 'my_passw0rd',
#   resource_name   => 'jdbc/myMysqlDb',
#   host            => 'localhost',
#   use_unicode     => false,
#   character_encoding => 'latin-1',
#   fast_date_parsing  => true,
#   initial_size    => 5,
#   max_active      => 99,
#   max_idle        => 1,
#   jmx_enabled     => false,
#  }
#
# === Authors
#
# Sander Bilo <sander@proteon.nl>
#
# === Copyright
#
# Copyright 2013 Proteon.
#
define tomcat::jndi::database::mysql (
    $database,
    $username,
    $password,
    $instance,
    $resource_name      = 'jdbc/MysqlPool',
    $host               = 'localhost',
    $hosts              = [],
    $driver             = 'com.mysql.jdbc.Driver',
    $use_unicode        = true,
    $character_encoding = 'UTF-8',
    $fast_date_parsing  = false,
    $initial_size       = '10',
    $max_active         = '100',
    $max_idle           = '10',
    $min_evictable_time = '600000',
    $eviction_interval  = '60000',
    $jmx_enabled        = true,
    $auto_reconnect     = true,
    $validation_query   = 'SELECT 1',
    $loadbalanced       = false,
    $additional_properties = [],
    $additional_attributes = [],
    $type                  = 'context',
) {

    if ( $loadbalanced == true or $loadbalanced == 'true') {
        $jdbc_prefix = 'jdbc:mysql:loadbalance:'
        $subname = 'loadbalance'
    } else {
        $jdbc_prefix = 'jdbc:mysql:'
        $subname = undef
    }

    if ( empty($hosts) ) {
        $_hosts = [$host]
    } else {
        $_hosts = $hosts
    }

    $subprotocol = 'mysql'
    $_fixed_properties = [
        { 'useUnicode'         => $use_unicode },
        { 'characterEncoding'  => $character_encoding },
        { 'useFastDateParsing' => $fast_date_parsing },
        { 'autoReconnect'      => $auto_reconnect },
    ]
    $properties = concat($_fixed_properties, $additional_properties)

    $_uri = inline_template('jdbc:<%= @subprotocol %>:<% if @subname %><%= @subname %>:<% end %>//<% @_hosts.each_with_index do |host,index| -%><%= host %><%= "," if index < (@_hosts.size - 1) %><% end -%>/<%= @database %>?<% @properties.each_with_index do |property,index| -%><% property.keys.each do |key| -%><%= key %>=<%= property[key] %><%= "&amp;" if index < (@properties.size - 1) %><% end -%><% end -%>')

    $_fixed_attributes = [
        {'auth' => 'Container'},
        {'username' => $username},
        {'password' => $password},
        {'driverClassName' => $driver},
        {'url' => $_uri},
        {'initialSize'=> $initial_size },
        {'maxActive' => $max_active },
        {'maxIdle' => $max_idle },
        {'minEvictableIdleTimeMillis' => $min_evictable_time },
        {'timeBetweenEvictionRunsMillis' => $eviction_interval },
        {'jmxEnabled' => $jmx_enabled },
        {'validationQuery' => $validation_query },
    ]

    $attributes = concat($_fixed_attributes, $additional_attributes)

    tomcat::jndi::resource { "${instance}:${resource_name}":
        instance      => $instance,
        resource_name => $resource_name,
        attributes    => $attributes, 
        type          => $type,
    }

    if( $type == 'server' ) {
        tomcat::jndi::resourcelink { "resourcelink for ${instance}:${resource_name}":
            instance      => $instance,
            resourcelink_name => $resource_name,
            attributes    => [ {'global' => $resource_name }, { 'type' => 'javax.sql.DataSource' },]
        }
    }

    if(!defined(Tomcat::Lib::Maven["${instance}:mysql-connector-java"])) {
	    tomcat::lib::maven { "${instance}:mysql-connector-java":
	        lib        => 'mysql-connector-java.jar',
	        instance   => $instance,
	        groupid    => 'mysql',
	        artifactid => 'mysql-connector-java',
	        version    => '5.1.29',
	    }
    }
}
