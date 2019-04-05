# Installs and configures a LAMP stack

exec { 'create localhost cert':
    # lint:ignore:140chars
    # lint:ignore:80chars
    command   => "/bin/openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -sha256 -subj '/CN=domain.com/O=My Company Name LTD./C=US' -keyout /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt",
    # lint:endignore
    # lint:endignore
    creates   => '/etc/pki/tls/certs/localhost.crt',
    logoutput => true,
    before    => Class['apache'],
  }

class { 'apache::version':
  scl_httpd_version =>'2.4',
  scl_php_version   =>'7.3',
}

class { 'apache':
  default_vhost => false,
  default_mods  => false,
  mpm_module    => 'event',  
}

apache::vhost { 'localhost-nossl':
  port    => '80',
  docroot => '/vagrant/htdocs',
}

apache::vhost { 'localhost':
  port    => '443',
  docroot => '/vagrant/htdocs',
  ssl     => true,
}
