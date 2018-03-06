# == Class: Tomcat
#
# === Parameters
#
# [*version*] The tomcat version to install, defaults to 7.
#
# === Variables
#
# === Examples
#
#  class { tomcat:
#    version  => 6
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
class tomcat (
    $version = $tomcat::params::version,
    $start_on_boot = true,
) inherits tomcat::params {
    include concat::setup

    package { "tomcat${version}": ensure => held, }

    package { ['libtcnative-1', 'liblog4j1.2-java', 'libcommons-logging-java']: ensure => held, }

    File {
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
        

    file { [$tomcat::params::root, $tomcat::params::home, '/etc/tomcat.d/',]:
        ensure => directory,
    }

    file { '/etc/init.d/tomcat':
        source => 'puppet:///modules/tomcat/tomcat',
        mode   => '0755',
    }

    file { '/usr/sbin/tomcat':
        ensure => link,
        target => '/etc/init.d/tomcat',
    }

    service { "tomcat${version}":
        ensure  => stopped,
        pattern => "/var/lib/tomcat${version}",
        enable  => false,
        require => Package["tomcat${version}"],
    }

    exec { 'create tomcat init script links':
        command => '/usr/sbin/update-rc.d tomcat defaults',
        creates => '/etc/rc0.d/K01tomcat',
        require => File['/etc/init.d/tomcat'],
    }

    if $start_on_boot {
        exec { 'enable tomcat autostarting':
            command => '/usr/sbin/update-rc.d tomcat enable',
            creates => '/etc/rc2.d/S02tomcat',
            require => [
                File['/etc/init.d/tomcat'],
                Exec['create tomcat init script links'],
            ],
        }
    } else {
        exec { 'disable tomcat autostarting':
            command => '/usr/sbin/update-rc.d tomcat disable',
            onlyif  => '/bin/bash -c "[[ -L /etc/rc2.d/S02tomcat ]]"',
            require => [
                File['/etc/init.d/tomcat'],
                Exec['create tomcat init script links'],
            ],
        }
    }

    profile_d::script { 'CATALINA_HOME.sh':
        ensure  => present,
        content => "export CATALINA_HOME=/usr/share/tomcat${version}",
    }

    profile_d::script { 'CATALINA_BASE.sh':
        ensure  => present,
        content => 'export CATALINA_BASE=$HOME/tomcat',
    }
}
