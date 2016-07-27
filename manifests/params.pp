# == Class: tomcat::params
#
# This class manages Tomcat parameters.
#
# === Parameters
#
# === Variables
#
# === Examples
#
# === Authors
#
# Sander Bilo <sander@proteon.nl>
#
# === Copyright
#
# Copyright 2013 Proteon.
#
class tomcat::params (
    $version = 7
) {
    $root                           = '/opt/tomcat'
    $home                           = "${root}/sites"
}
