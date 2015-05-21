# This resource installs a library (jar) from a maven repository in an instance.
#
# === Parameters
#
# Document parameters here.
#
# [*lib*]           The outputfile (artifactid). Defaults to $name.jar
# [*instance*]      The instance this library should be installed in (see tomcat::instance).
# [*groupid*]       The groupid of the library to install.
# [*artifactid*]    The artifactid of the library to install.
# [*version*]       The version of the library to install.
#
# === Variables
#
# === Examples
#
#  tomcat::lib::maven { 'mysql-connector-java-5.1.24':
#   instance   => 'instance_1',
#   groupid    => 'mysql',
#   artifactid => 'mysql-connector-java',
#   version    => '5.1.24',
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
define tomcat::lib::maven ($lib = "${name}.jar", $instance, $groupid, $artifactid, $version, $classifier = undef, $repos = []) {
  include ::maven

  if ($classifier) {
    $suffix = "-${classifier}"
  } else {
    $suffix = ''
  }

  if (!defined(Maven["/usr/share/java/${artifactid}-${version}${suffix}.jar"])) {
    maven { "/usr/share/java/${artifactid}-${version}${suffix}.jar":
      groupid    => $groupid,
      artifactid => $artifactid,
      version    => $version,
      packaging  => 'jar',
      repos      => $repos,
      classifier => $classifier,
    }
  }

  
  ensure_resource('file', "${tomcat::params::home}/${instance}/tomcat/.lib/", { 'ensure' => 'directory', })

  file { "${tomcat::params::home}/${instance}/tomcat/.lib/${lib}":
    ensure  => 'link',
    target  => "/usr/share/java/${artifactid}-${version}${suffix}.jar",
    force   => true,
    require => [Maven["/usr/share/java/${artifactid}-${version}${suffix}.jar"],File["${tomcat::params::home}/${instance}/tomcat/.lib/"]],
  }

  exec { "delete old lib version for ${instance}-${version}-${lib}":
    command => "/bin/rm -f ${tomcat::params::home}/${instance}/tomcat/lib/${lib}",
    refreshonly => true,
    subscribe => File["${tomcat::params::home}/${instance}/tomcat/.lib/${lib}"],
    before => File["${tomcat::params::home}/${instance}/tomcat/lib/${lib}"],
  }

  file { "${tomcat::params::home}/${instance}/tomcat/lib/${lib}":
    ensure => 'file',
    source => "${tomcat::params::home}/${instance}/tomcat/.lib/${lib}",
    replace => false,
    links  => 'follow',
    require => File["${tomcat::params::home}/${instance}/tomcat/.lib/${lib}"],
    notify  => Tomcat::Service[$instance],
  }
}
