# Class: nginx
#
# This class manages nginx vhosts.
#
# Parameters:
#   $nginx_port
#       the port nginx should listen on
#
#
# Actions:
#   Manages nginx and nginx vhosts.
#
# Requires:
#   - Package["nginx"]
#
# Sample Usage:
#
#   nginx::vhost { "foo.bar.com":
#       vhost => "foo",
#       domain => "bar.com"
#       packages => ["php5-cgi"]
#   }

class nginx {
	package{ "nginx": ensure => installed }

	if $nginx_port {
		$port = $nginx_port
	} else {
		$port = "8000"
	}

	service { nginx:
		ensure => running,
		enable => true,
	}

	file{["/etc/nginx/sites-available/default", "/etc/nginx/sites-enabled/default"]:
		ensure => absent
	}

	file{"/var/www/nginx-default":
		ensure => absent,
		force => true
	}

	dir{$vhosts:
		dir => "/var/log/nginx",
	}

	define dir($dir){
		file{"$dir/$name":
			ensure => directory,
			owner => root,
			group => root,
			before => Service["nginx"],
		}
	}

	define vhost($vhost, $domain, $packages, $port=$port){
		include "nginx"

		$linkname = "${name}.conf"

		file{"/etc/nginx/sites-available/${name}.conf":
			owner => root,
			group => root,
			mode => 0444,
			content => template("nginx/vhost.conf.erb"),
			notify => Service["nginx"],
			before => File["/etc/nginx/sites-enabled/$linkname"]
		}

		file{"/etc/nginx/sites-enabled/$linkname":
			owner => root,
			group => root,
			mode => 0444,
			ensure => "/etc/nginx/sites-available/${name}.conf",
			notify => Service["nginx"]
		}

		file{"/var/www/${domain}/${vhost}/configs/nginx.conf":
			owner => root,
			group => root,
			mode => 0644,
			ensure => 'present',
			notify => Service["nginx"]
		}

		package{$packages:
			ensure => latest,
			notify => Service["nginx"],
		}

	}

}

