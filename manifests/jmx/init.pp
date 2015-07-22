define tomcat::jmx::init (
    $instance = $name) {
    include concat::setup

    concat { "${tomcat::params::home}/${instance}/tomcat/conf/jmxremote.password":
        owner   => $instance,
        group   => $instance,
        mode    => '0600',
        require => File["${tomcat::params::home}/${instance}/tomcat/conf"],
    }

    concat { "${tomcat::params::home}/${instance}/tomcat/conf/jmxremote.access":
        owner   => $instance,
        group   => $instance,
        mode    => '0640',
        require => File["${tomcat::params::home}/${instance}/tomcat/conf"],
    }
}
