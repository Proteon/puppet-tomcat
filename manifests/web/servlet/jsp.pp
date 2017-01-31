# This resource installs the default servlet into the global web.xml.
#
# === Authors
#
# Sander Bilo <sander@proteon.nl>
#
# === Copyright
#
# Copyright 2013 Proteon.
#
define tomcat::web::servlet::jsp (
    $instance                   = $name,
    $clazz                      = 'org.apache.jasper.servlet.JspServlet',
    $servlet_name               = 'jsp',
    $development                = false,
    $fork                       = true,
    $gen_string_as_char_array   = true,
    $trim_spaces                = true,
    $x_powered_by               = false,
    $mapped_file                = false,
    $modification_test_interval = 4,
    $mappings                   = ['*.jsp', '*.jspx'],
    $load_on_startup            = 3
) {
    tomcat::web::servlet { "${instance}:${servlet_name}":
        instance        => $instance,
        clazz           => $clazz,
        servlet_name    => $servlet_name,
        load_on_startup => $load_on_startup,
        init_params     => [{
                'development' => $development
            }
            , {
                'fork' => $fork
            }
            , {
                'genStringAsCharArray' => $gen_string_as_char_array
            }
            , {
                'modificationTestInterval' => $modification_test_interval
            }
            , {
                'trimSpaces' => $trim_spaces
            }
            , {
                'xpoweredBy' => $x_powered_by
            }
            , {
                'mappedFile' => $mapped_file
            }
            ],
        mappings        => $mappings,
    }
}
