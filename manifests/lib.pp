# This resource installs a tomcat lib (a jar file).
#
# === Parameters
#
# Document parameters here.
#
# [*instance*]   The instance this definition should be installed in (see tomcat::instance).
# [*lib*]        The name of the output file (.jar).
# [*source*]     The library to install (a jar file).
#
# === Variables
#
# === Examples
#
#  tomcat::lib { 'mysql-connector-java-5.1.24-bin.jar':
#   instance => 'instance_1',
#   source   => 'puppet:///mysql/mysql-connector-java-5.1.24-bin.jar',
#  }
# === Authors
#
# Sander Bilo <sander@proteon.nl>
#
# === Copyright
#
# Copyright 2013 Proteon.
#
define tomcat::lib ($instance, $lib = "${name}.jar", $source) {
    file { "${tomcat::params::home}/${instance}/tomcat/lib/${lib}":
        source => $source,
        owner  => $instance,
        group  => $instance,
        mode   => '0644',
        notify => Tomcat::Service[$instance],
    }
}

