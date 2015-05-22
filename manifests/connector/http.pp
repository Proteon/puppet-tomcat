# ==== Resource: tomcat::connector::http
#
# This resource creates a tomcat connector, see : http://tomcat.apache.org/tomcat-7.0-doc/config/http.html
#
# === Parameters
#
# === Authors
#
# Sander Bilo <sander@proteon.nl>
# Simon Smit <simon.johannes.smit@gmail.com>
# === Copyright
#
# Copyright 2013 Proteon.
#
define tomcat::connector::http (
    $ensure                 = present,
    $instance               = $name,
    $address                = '0.0.0.0',
    $port                   = 8080,
    $scheme                 = 'http',
    $uri_encoding           = 'UTF-8',
    $max_threads            = 800,
    $min_spare_threads      = 80,
    $compression            = 'on',
    $secure                 = false,
    $compressable_mime_type = 'text/html,text/xml,text/plain',
    $proxy_port		    = undef,
) {

    $_default_attributes = [
        { 'address' => $address },
        { 'scheme' => $scheme },
        { 'maxThreads' => $max_threads },
        { 'minSpareThreads' => $min_spare_threads },
        { 'compression' => $compression },
        { 'compressableMimeType' => $compressable_mime_type },
        { 'secure' => $secure },
    ]
 
    if ($proxy_port ) {
        $_attributes = concat($_default_attributes, [{ 'proxyPort' => $proxy_port }])
    } else {
    	$_attributes = $_default_attributes
    }

    tomcat::connector { $name:
        ensure       => $ensure,
        instance     => $instance,
        port         => $port,
        uri_encoding => $uri_encoding,
        attributes   => $_attributes
    }
}
