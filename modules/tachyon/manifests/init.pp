# A Chassis extension to install and run tachyon
class tachyon (
  $config,
  $fqdn = $::fqdn,
  $php  = $config[php]
) {

	# Default settings for install
	$defaults = {
		'port'  => 8082,
	}

	if versioncmp($php, '5.4') <= 0 {
		$php_package = 'php5'
	}
	else {
		$php_package = "php${php}"
	}

	# Allow override from config.yaml
	$options = deep_merge($defaults, $config[tachyon])

	# Allow disabling the extension
	if ( !empty($config[disabled_extensions]) and 'chassis/tachyon' in $config[disabled_extensions] ) {
		$package = absent
		$service = stopped
		$active  = false
	} else {
		$package = present
		$service = running
		$active  = true
	}

	# Get template vars
	$port    = $options[port]
	$content = $config[mapped_paths][content]

	package { 'libpng-dev':
		ensure  => $package,
		require => [
			Apt::Ppa['ppa:ondrej/php'],
			Apt::Ppa['ppa:ondrej/php-qa'],
			Class['apt::update'],
		],
		notify  => Service["${php_package}-fpm"]
	}

	# Install and start
	exec { 'tachyon install aws-sdk':
		command => '/usr/bin/yarn add aws-sdk',
		cwd     => '/vagrant/extensions/tachyon/server',
		user    => 'vagrant',
		unless  => '/usr/bin/test -d /vagrant/extensions/tachyon/server/node_modules/aws-sdk',
		require => [
			Package['nodejs'],
			Exec['install yarn'],
		],
	}

	exec { 'tachyon install':
		command => '/usr/bin/yarn',
		cwd     => '/vagrant/extensions/tachyon/server',
		user    => 'vagrant',
		unless  => '/usr/bin/test -d /vagrant/extensions/tachyon/server/node_modules/sharp',
		require => [
			Package['nodejs'],
			Exec['tachyon install aws-sdk'],
		],
	}

	exec { 'systemctl enable tachyon':
		command     => '/bin/systemctl enable tachyon',
		refreshonly => true,
	}

  # Create service file
	file { '/lib/systemd/system/tachyon.service':
		ensure  => file,
		mode    => '0644',
		content => template('tachyon/systemd.service.erb'),
		notify  => [
			Exec['systemctl-daemon-reload'],
			Exec['systemctl enable tachyon'],
		],
	}

	File['/lib/systemd/system/tachyon.service'] -> Service['tachyon']

	service { 'tachyon':
		ensure    => $service,
		enable    => $active,
		restart   => $active,
		hasstatus => $active,
		require   => Exec['tachyon install'],
	}

	# Configure nginx
	file { "/etc/nginx/sites-available/${fqdn}.d/tachyon.nginx.conf":
		ensure  => $package,
		content => template('tachyon/nginx.conf.erb'),
		notify  => Service['nginx'],
		require => File["/etc/nginx/sites-available/${fqdn}.d"],
	}

}
