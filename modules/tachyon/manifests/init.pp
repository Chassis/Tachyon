# A Chassis extension to install and run tachyon
class tachyon (
  $config,
  $fqdn = $::fqdn,
) {

	# Default settings for install
	$defaults = {
		'port'  => 8082,
	}

	# Allow override from config.yaml
	$options = deep_merge($defaults, $config[tachyon])

	# Allow disabling the extension
	if ( !empty($config[disabled_extensions]) and 'chassis/tachyon' in $config[disabled_extensions] ) {
		$package = absent
		$service = stopped
	} else {
		$package = present
		$service = running
	}

	# Get template vars
	$port    = $options[port]
	$content = $config[mapped_paths][content]

	# Install and start.
	exec { 'tachyon install aws-sdk':
		command => '/usr/bin/npm install aws-sdk',
		cwd     => '/vagrant/extensions/tachyon/server',
		user    => 'vagrant',
		unless  => '/usr/bin/test -d /opt/tachyon/node_modules/aws-sdk',
		require => Package['nodejs'],
	}

	exec { 'tachyon install':
		command => '/usr/bin/npm install',
		cwd     => '/vagrant/extensions/tachyon/server',
		user    => 'vagrant',
		unless  => '/usr/bin/test -d /vagrant/extensions/tachyon/server/node_modules/sharp',
		require => [
			Package['nodejs'],
			Exec['tachyon install aws-sdk'],
		],
	}

	service { 'tachyon':
		ensure    => $service,
		hasstatus => true,
		provider  => 'base',
		start     => "cd ${content} && /usr/bin/node /vagrant/extensions/tachyon/server/local-server.js ${port} &>/dev/null &",
		stop      => '/bin/kill -9 $(ps -ef | grep [t]achyon/server | awk \'{print $2}\')',
		status    => "/bin/ps -ef | grep [t]achyon/server",
		require   => Exec['tachyon install']
	}

	# Configure nginx
	if ( ! defined( File["/etc/nginx/sites-available/${fqdn}.d"] ) ) {
		file{ "/etc/nginx/sites-available/${fqdn}.d/":
			ensure  => directory,
			require => Package['nginx'],
		}
	}

	file { "/etc/nginx/sites-available/${fqdn}.d/tachyon.nginx.conf":
		ensure  => $package,
		content => template('tachyon/nginx.conf.erb'),
		notify  => Service['nginx'],
		require => File["/etc/nginx/sites-available/${fqdn}.d"],
	}

}
