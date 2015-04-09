#adds a valve to tomcats setup
define tomcat::valve::valve (
    $instance = $name,
    $ensure   = present,
    $type     = 'engine',
    $attributes    = [],
) {
    concat::fragment { "Adding Valve ${name} for ${instance}":
        target  => "${tomcat::params::home}/${instance}/tomcat/conf/${type}-valves.xml",
        order   => 01,
        content => template('tomcat/valve.xml.erb'),
#        require => File["${tomcat::params::home}/${instance}/tomcat/conf/${type}-valves.xml"],
    }
}
