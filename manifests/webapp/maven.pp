# This resource installs a web application from a maven repository in an instance.
#
# === Parameters
#
# Document parameters here.
#
# [*webapp*]        The name of the application (context). Defaults to $name
# [*instance*]      The instance this application should be installed in (see tomcat::instance).
# [*groupid*]       The groupid of the application to install.
# [*artifactid*]    The artifact of the application to install.
# [*version*]       The version of the application to install.
#
# === Variables
#
# === Examples
#
#  tomcat::webapp::maven { 'ROOT':
#   instance   => 'instance_1',
#   groupid    => 'org.sonatype.nexus',
#   artifactid => 'nexus-webapp',
#   version    => '2.3.1-01',
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
define tomcat::webapp::maven (
    $webapp = $name,
    $instance,
    $groupid,
    $artifactid,
    $version,
    $repos  = []) {
    include maven
    include tomcat

    $notify = $webapp ? {
        'ROOT'  => Exec["${name}@${instance}:clean"],
        default => Exec["${name}@${instance}:deploy-${webapp}"],
    }

    ensure_resource('file', "${tomcat::params::home}/${instance}/tomcat/.plugins/", { 'ensure' => 'directory', })

    if (!defined(Maven["/usr/share/java/${artifactid}-${version}.war"])) {
        maven { "/usr/share/java/${artifactid}-${version}.war":
            groupid    => $groupid,
            artifactid => $artifactid,
            version    => $version,
            packaging  => 'war',
            repos      => $repos,
        }
    }

    file { "${tomcat::params::home}/${instance}/tomcat/.plugins/${webapp}.war":
        ensure  => 'link',
        target  => "/usr/share/java/${artifactid}-${version}.war",
        force   => true,
        require => [Maven["/usr/share/java/${artifactid}-${version}.war"], File["${tomcat::params::home}/${instance}/tomcat/.plugins/"]],
        notify  => $notify,
    }

    #exec to cp war from .plugins to webapps after symlink is made.
    exec { "${name}@${instance}:deploy-${webapp}":
        command => "/bin/cp -L ${tomcat::params::home}/${instance}/tomcat/.plugins/${webapp}.war ${tomcat::params::home}/${instance}/tomcat/webapps/${webapp}.war",
        refreshonly => true,
        creates => "${tomcat::params::home}/${instance}/tomcat/webapps/${webapp}.war",
        notify  => Tomcat::Service[$instance],
    }

    exec { "${name}@${instance}:clean":
        command     => "/etc/init.d/tomcat stop --instance=${instance}; rm -rf ${tomcat::params::home}/${instance}/tomcat/webapps/ROOT ${tomcat::params::home}/${instance}/tomcat/temp/* ${tomcat::params::home}/${instance}/tomcat/work/*",
        refreshonly => true,
        notify      => Exec["${name}@${instance}:deploy-${webapp}"],
    }
}
