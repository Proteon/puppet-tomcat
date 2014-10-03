# This resource installs a tomcat instance.
#
# === Parameters
#
# Document parameters here.
#
# [*shutdown_port*]     The port the shutdown command can be issued to. Defaults to 8005.
# [*apr_enabled*]       Enable apr. Defaults to true.
# [*pidfile_enabled*]   Enable pid file. Defaults to true.
# [*jmx_enabled*]       Enable jmx. Defaults to false,
# [*jmx_ip*]            Ip address to bind jmx on. Defaults to '127.0.0.1',
# [*jmx_port*]          Port to bind jmx on. Defaults to 8050,
# [*jmx_ssl*]           Use ssl for jmx. Defaults to false,
# [*jmx_authenticate*]  Use authentication on jmx. Defaults to false,
# [*max_heap*]          Max heap space to use. Defaults to 1024m.
# [*min_heap*]          Min heap space to use. Defaults to 1024m.
# [*min_perm*]          Min permgen space. Defaults to 384m.
# [*max_perm*]          Max permgen space. Defaults to 384m.
# [*unpack_wars*]       Unpack wars. Defaults to true.
# [*auto_deploy*]       Auto deploy wars. Defaults to true.
# [*deploy_on_startup*] Deploy applications on startup. Defaults to true.
# [*java_version*]      Java installation to set in JAVA_HOME. See Proteon/Java module for all options. Defaults to openjdk_1_7_0.
# [*tomcat_version*]    Explicitly request a version of tomcat for this instance. This depends on the major version specified by the
#                       debian package. If the debian package specifies tomcat7 only tomcat7 versions like : 7.0.52 or 7.0.18 are
#                       allowed.
#                       Defaults to the debian provided version.
# [*tomee_version*]     Install tomee for this instance, make sure the instance tomcat version is compatible with the tomee version
#                       specified. Defaults to undef (don't install tomee).
# [*catalina_opts*]     Array of extra catalina_opts. Defaults to '-d64', '-XX:SurvivorRatio=65536', '-XX:TargetSurvivorRatio=0',
#                       '-XX:MaxTenuringThreshold=0', '-XX:+UseParNewGC', '-XX:ParallelGCThreads=2', '-XX:+UseConcMarkSweepGC',
#                       '-XX:+CMSParallelRemarkEnabled', '-XX:+CMSCompactWhenClearAllSoftRefs',
#                       '-XX:CMSInitiatingOccupancyFraction=85',
#                       '-XX:+CMSScavengeBeforeRemark', '-XX:+UseCompressedOops', '-XX:+DisableExplicitGC', '-Dfile.encoding=UTF-8'
# [*ensure*]            Ensure present or absent for this instance (experimental). Defaults to present
#
# === Variables
#
# === Examples
#
#  tomcat::instance { 'instance_1':
#   shutdown_port => '8006',
#   apr_enabled   => true,
#   max_heap      => '2048m',
#   min_heap      => '1024m',
#   min_perm      => '384m',
#   max_perm      => '512m',
#   unpack_wars   => false,
#   auto_deploy   => true,
#   java_version  => 'oracle_1_8_0',
#   catalina_opts => ['-server, '-XX:+UseParNewGC', '-XX:ParallelGCThreads=2'],
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
define tomcat::instance (
  $shutdown_port     = 8005,
  $apr_enabled       = true,
  $pidfile_enabled   = true,
  $jmx_enabled       = false,
  $jmx_ip            = '127.0.0.1',
  $jmx_port          = 8050,
  $jmx_ssl           = false,
  $jmx_authenticate  = false,
  $max_heap          = '1024m',
  $min_heap          = '1024m',
  $min_perm          = '384m',
  $max_perm          = '384m',
  $unpack_wars       = true,
  $auto_deploy       = true,
  $deploy_on_startup = true,
  $java_version      = 'openjdk_1_7_0',
  $tomcat_version    = undef,
  $tomee_version     = undef,
  $rotatelogs        = false,
  $rotatelogs_bin    = '/usr/sbin/rotatelogs',
  $rotatelogs_options = '',
  $rotatelogs_file_size = 1024M,
  $catalina_opts     = [
    '-d64',
    '-XX:SurvivorRatio=65536',
    '-XX:TargetSurvivorRatio=0',
    '-XX:MaxTenuringThreshold=0',
    '-XX:+UseParNewGC',
    '-XX:ParallelGCThreads=2',
    '-XX:+UseConcMarkSweepGC',
    '-XX:+CMSParallelRemarkEnabled',
    '-XX:+CMSCompactWhenClearAllSoftRefs',
    '-XX:CMSInitiatingOccupancyFraction=85',
    '-XX:+CMSScavengeBeforeRemark',
    '-XX:+UseCompressedOops',
    '-XX:+DisableExplicitGC',
    '-Dfile.encoding=UTF-8'],
  $ensure            = present,) {
  include tomcat

  $java_class_name = "::java::${java_version}"

  if (!defined(Class[$java_class_name])) {
    class { $java_class_name: }
  }
  
  $derived_tomcat_version = $tomee_version ? {
    undef   => $tomcat_version ? {
      undef   => $::lsbdistrelease ? {
        '12.04' => '7.0.26',
        '14.04' => '7.0.52',
      },
      default => $tomcat_version,
    },
    '1.6.0'   => '7.0.47',
    '1.6.0.2' => '7.0.53',
    '1.7.0'   => '7.0.55',
  }

  if ($derived_tomcat_version >= '7.0.19') {
    tomcat::lib::maven { "${name}:tomcat-jdbc":
      instance   => $name,
      lib        => 'tomcat-jdbc.jar',
      groupid    => 'org.apache.tomcat',
      artifactid => 'tomcat-jdbc',
      version    => $derived_tomcat_version,
    }
  }

  Tomcat::Lib::Maven {
    instance => $name,
    groupid  => 'org.apache.tomcat',
    version  => $derived_tomcat_version,
  }

  if ($tomcat_version) {
    tomcat::lib::maven { "${name}:commons-pool":
      lib        => 'commons-pool.jar',
      groupid    => 'commons-pool',
      artifactid => 'commons-pool',
      version    => '1.6',
    }

    if (!$tomee_version) {
      tomcat::lib::maven { "${name}:tomcat-annotations-api":
        lib        => 'tomcat-annotations-api.jar',
        artifactid => 'tomcat-annotations-api',
      }

      tomcat::lib::maven { "${name}:tomcat-el-api":
        lib        => 'tomcat-el-api.jar',
        artifactid => 'tomcat-el-api',
      }
    }

    tomcat::lib::maven { "${name}:tomcat-api":
      lib        => 'tomcat-api.jar',
      artifactid => 'tomcat-api',
    }

    tomcat::lib::maven { "${name}:tomcat-catalina-ant":
      lib        => 'tomcat-catalina-ant.jar',
      artifactid => 'tomcat-catalina-ant',
    }

    tomcat::lib::maven { "${name}:tomcat-catalina-ha":
      lib        => 'tomcat-catalina-ha.jar',
      artifactid => 'tomcat-catalina-ha',
    }

    tomcat::lib::maven { "${name}:tomcat-catalina":
      lib        => 'tomcat-catalina.jar',
      artifactid => 'tomcat-catalina',
    }

    tomcat::lib::maven { "${name}:tomcat-coyote":
      lib        => 'tomcat-coyote.jar',
      artifactid => 'tomcat-coyote',
    }

    tomcat::lib::maven { "${name}:tomcat-dbcp":
      lib        => 'tomcat-dbcp.jar',
      artifactid => 'tomcat-dbcp',
    }

    tomcat::lib::maven { "${name}:tomcat-i18n-ja":
      lib        => 'tomcat-i18n-ja.jar',
      artifactid => 'tomcat-i18n-ja',
    }

    tomcat::lib::maven { "${name}:tomcat-i18n-fr":
      lib        => 'tomcat-i18n-fr.jar',
      artifactid => 'tomcat-i18n-fr',
    }

    tomcat::lib::maven { "${name}:tomcat-i18n-es":
      lib        => 'tomcat-i18n-es.jar',
      artifactid => 'tomcat-i18n-es',
    }

    tomcat::lib::maven { "${name}:tomcat-jasper-el":
      lib        => 'tomcat-jasper-el.jar',
      artifactid => 'tomcat-jasper-el',
    }

    tomcat::lib::maven { "${name}:tomcat-jasper":
      lib        => 'tomcat-jasper.jar',
      artifactid => 'tomcat-jasper',
    }

    tomcat::lib::maven { "${name}:tomcat-jsp-api":
      lib        => 'tomcat-jsp-api.jar',
      artifactid => 'tomcat-jsp-api',
    }

    tomcat::lib::maven { "${name}:tomcat-servlet-api":
      lib        => 'tomcat-servlet-api.jar',
      artifactid => 'tomcat-servlet-api',
    }

    tomcat::lib::maven { "${name}:tomcat-tribes":
      lib        => 'tomcat-tribes.jar',
      artifactid => 'tomcat-tribes',
    }

    tomcat::lib::maven { "${name}:tomcat-util":
      lib        => 'tomcat-util.jar',
      artifactid => 'tomcat-util',
    }

    if ($derived_tomcat_version >= '7.0.47') {
      tomcat::lib::maven { "${name}:tomcat-websocket-api":
        lib        => 'tomcat-websocket-api.jar',
        artifactid => 'tomcat-websocket-api',
      }

      if ($derived_tomcat_version < '8.0.0') {
        tomcat::lib::maven { "${name}:tomcat7-websocket":
          lib        => 'tomcat7-websocket.jar',
          artifactid => 'tomcat7-websocket',
        }
      }

      if ($derived_tomcat_version >= '8.0.0') {
        tomcat::lib::maven { "${name}:tomcat-websocket":
          lib        => 'tomcat-websocket.jar',
          artifactid => 'tomcat-websocket',
        }
      }
    }
  }

  if ($tomee_version) {
    tomcat::tomee::init { $name: version => $tomee_version }
  }

  $java_home_name = "::java::${java_version}::home"

  $instance_home = "${tomcat::params::home}/${name}"

  tomcat::service { $name:
    ensure => $ensure ? {
      present => 'running',
      absent  => 'stopped',
      default => 'running',
    }
  }

  tomcat::connector::init { $name:
    ensure => $ensure,
    notify => Tomcat::Service[$name],
  }

  tomcat::listener::init { $name:
    ensure => $ensure,
    notify => Tomcat::Service[$name],
  }

  tomcat::jndi::init { $name:
    ensure => $ensure,
    notify => Tomcat::Service[$name],
  }

  tomcat::realm::init { $name:
    ensure => $ensure,
    notify => Tomcat::Service[$name],
  }

  tomcat::valve::init { $name:
    ensure => $ensure,
    notify => Tomcat::Service[$name],
  }

  tomcat::cluster::init { $name:
    ensure => $ensure,
    notify => Tomcat::Service[$name],
  }

  tomcat::web::init { $name:
    ensure         => $ensure,
    tomcat_version => $derived_tomcat_version,
    notify         => Tomcat::Service[$name],
  }

  if (!defined(Tomcat::Web::Servlet["${name}:default"])) {
    tomcat::web::servlet::default { $name: }
  }

  if (!defined(Tomcat::Web::Servlet["${name}:jsp"])) {
    tomcat::web::servlet::jsp { $name: }
  }

  if (!defined(Tomcat::Connector[$name])) {
    tomcat::connector::http { $name: ensure => $ensure, }
  }

  if ($apr_enabled and !$tomcat_version) {
    tomcat::listener { "${name}:org.apache.catalina.core.AprLifecycleListener":
      instance   => $name,
      class_name => 'org.apache.catalina.core.AprLifecycleListener',
      attributes => [{
          'SSLEngine' => 'on',
        }
        ],
    }
  }

  if ($jmx_enabled and $jmx_authenticate) {
    tomcat::jmx::init { $name: }
  }

  tomcat::listener { "${name}:org.apache.catalina.core.JasperListener":
    instance   => $name,
    class_name => 'org.apache.catalina.core.JasperListener',
  }

  tomcat::listener { "${name}:org.apache.catalina.core.JreMemoryLeakPreventionListener":
    instance   => $name,
    class_name => 'org.apache.catalina.core.JreMemoryLeakPreventionListener',
  }

  if ($tomcat::version < 7) {
    tomcat::listener { "${name}:org.apache.catalina.mbeans.ServerLifecycleListener":
      instance   => $name,
      class_name => 'org.apache.catalina.mbeans.ServerLifecycleListener',
    }
  }

  tomcat::listener { "${name}:org.apache.catalina.mbeans.GlobalResourcesLifecycleListener":
    instance   => $name,
    class_name => 'org.apache.catalina.mbeans.GlobalResourcesLifecycleListener',
  }

  file { [
    $instance_home,
    "${instance_home}/tomcat",
    "${instance_home}/tomcat/bin",
    "${instance_home}/tomcat/conf",
    "${instance_home}/tomcat/conf/Catalina",
    "${instance_home}/tomcat/conf/Catalina/localhost",
    "${instance_home}/tomcat/lib",
    "${instance_home}/tomcat/logs",
    "${instance_home}/tomcat/temp",
    "${instance_home}/tomcat/webapps",
    "${instance_home}/tomcat/work"]:
    ensure  => directory,
    owner   => $name,
    group   => $name,
    mode    => '0640',
    require => [User[$name], Class['tomcat']],
  }

  file { "${instance_home}/tomcat/bin/bootstrap.jar":
    ensure => link,
    target => "/usr/share/tomcat${tomcat::version}/bin/bootstrap.jar",
    notify => Tomcat::Service[$name],
  }
  
  if ( ! $rotatelogs) {
    file { "${instance_home}/tomcat/bin/catalina.sh":
      ensure => file,
      source => "/usr/share/tomcat${tomcat::version}/bin/catalina.sh",
      owner  => 'root',
      group  => 'root',
      mode   => '755',
      notify => Tomcat::Service[$name],
    } 
  } else {
    if (!defined(Package['apache2-utils'])) {
      package { 'apache2-utils':
        ensure => "installed"
      }
    }
    file { "${instance_home}/tomcat/bin/catalina.sh":
      content => template('tomcat/catalina.sh.erb'),
      owner  => 'root',
      group  => 'root',
      mode   => '755',
      notify => Tomcat::Service[$name],
    }
 }


  file { "${instance_home}/tomcat/bin/digest.sh":
    ensure => link,
    target => "/usr/share/tomcat${tomcat::version}/bin/digest.sh",
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/bin/setclasspath.sh":
    ensure => link,
    target => "/usr/share/tomcat${tomcat::version}/bin/setclasspath.sh",
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/bin/shutdown.sh":
    ensure => file,
    source => "/usr/share/tomcat${tomcat::version}/bin/shutdown.sh",
    owner  => 'root',
    group  => 'root',
    mode   => '755',
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/bin/startup.sh":
    ensure => file,
    source => "/usr/share/tomcat${tomcat::version}/bin/startup.sh",
    owner  => 'root',
    group  => 'root',
    mode   => '755',
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/bin/tool-wrapper.sh":
    ensure => link,
    target => "/usr/share/tomcat${tomcat::version}/bin/tool-wrapper.sh",
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/bin/version.sh":
    ensure => link,
    target => "/usr/share/tomcat${tomcat::version}/bin/version.sh",
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/conf/catalina.properties":
    content => template('tomcat/catalina.properties.erb'),
    force   => true,
    notify  => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/conf/logging.properties":
    ensure => link,
    target => "/etc/tomcat${tomcat::version}/logging.properties",
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/conf/policy.d":
    ensure => link,
    target => "/etc/tomcat${tomcat::version}/policy.d",
    notify => Tomcat::Service[$name],
  }

  file { "${instance_home}/tomcat/bin/setenv.sh":
    content => template('tomcat/setenv.sh.erb'),
    notify  => Tomcat::Service[$name],
    owner   => $name,
    mode    => '0740',
  }

  user { $name:
    ensure   => present,
    home     => $instance_home,
    password => '!',
    comment  => "${name} instance user",
  }

  file { "/etc/tomcat.d/${name}":
    ensure  => $ensure,
    content => '',
    require => User[$name],
    notify  => Tomcat::Service[$name],
    mode    => '0640',
  }

  file { "${instance_home}/tomcat/conf/server.xml":
    ensure  => $ensure,
    owner   => $name,
    group   => $name,
    content => template('tomcat/server.xml.erb'),
    require => File["${instance_home}/tomcat"],
    notify  => Tomcat::Service[$name],
    mode    => '0640',
  }

  file { "${instance_home}/tomcat/conf/context.xml":
    ensure  => $ensure,
    owner   => $name,
    group   => $name,
    content => template('tomcat/context.xml.erb'),
    require => File["${instance_home}/tomcat"],
    notify  => Tomcat::Service[$name],
    mode    => '0640',
  }
}
