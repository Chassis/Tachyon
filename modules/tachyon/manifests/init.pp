# A Chassis extension to install and run tachyon
class tachyon (
  $config,
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
  $port = $options[port]
  $content = $config[mapped_paths][content]

  # Install and start.
  file { '/opt/tachyon':
    ensure => 'directory',
    owner  => 'vagrant',
  } ->
  exec { '/usr/bin/npm install aws-sdk':
    cwd     => '/opt/tachyon',
    user    => 'vagrant',
    unless  => '/usr/bin/test -d /opt/tachyon/node_modules/aws-sdk',
    require => Package['nodejs'],
  } ->
  exec { '/usr/bin/npm install humanmade/tachyon':
    cwd     => '/opt/tachyon',
    user    => 'vagrant',
    unless  => '/usr/bin/test -d /opt/tachyon/node_modules/node-tachyon',
  } ~>
  service { 'tachyon':
    ensure   => $service,
    hasstatus   => true,
    provider => 'base',
    start    => "cd ${content} && /usr/bin/node /opt/tachyon/node_modules/node-tachyon/local-server.js ${port} &>/dev/null &",
    stop     => 'kill -9 $(ps -ef | grep [t]achyon/node_modules | awk \'{print $2}\')',
    status   => "ps -ef | grep [t]achyon/node_modules",
  }

  # Configure nginx
  file { "/etc/nginx/sites-available/${fqdn}.d/tachyon.nginx.conf":
    ensure  => $package,
    content => template('tachyon/nginx.conf.erb'),
    notify  => Service['nginx'],
  }

}
