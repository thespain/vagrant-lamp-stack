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
  user          => 'vagrant',
  group         => 'vagrant',
  mpm_module    => 'event',
}

class { 'apache::mod::alias': }
class { 'apache::mod::dir': }
class { 'apache::mod::proxy': }
class { 'apache::mod::proxy_fcgi': }

apache::custom_config { 'php73-php-fpm':
  priority       => false,
  content  => '
AddType text/html .php
DirectoryIndex index.php
<FilesMatch \.php$>
    SetHandler "proxy:fcgi://127.0.0.1:9000"
</FilesMatch>
',
}

apache::vhost { 'localhost-nossl':
  port            => '80',
  docroot         => '/vagrant/htdocs',
  docroot_owner   => 'vagrant',
  docroot_group   => 'vagrant',
  directoryindex  => 'index.php',
  directories     => [
    {
      path => '/opt/rh/httpd24/root/var/www/phpmyadmin',
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      allow_override => ['None'],
      require        => ['all granted'],
    },
    {
      path => '/vagrant/htdocs',
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      allow_override => ['None'],
      require        => ['all granted'],
    }
  ],
  aliases         => [
    alias => '/phpmyadmin',
    path  => '/opt/rh/httpd24/root/var/www/phpmyadmin',
  ],
}

apache::vhost { 'localhost':
  port            => '443',
  docroot         => '/vagrant/htdocs',
  ssl             => true,
  docroot_owner   => 'vagrant',
  docroot_group   => 'vagrant',
  directoryindex  => 'index.php',
  directories     => [
    {
      path => '/opt/rh/httpd24/root/var/www/phpmyadmin',
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      allow_override => ['None'],
      require        => ['all granted'],
    },
    {
      path => '/vagrant/htdocs',
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      allow_override => ['None'],
      require        => ['all granted'],
    }
  ],
  aliases         => [
    alias => '/phpmyadmin',
    path  => '/opt/rh/httpd24/root/var/www/phpmyadmin',
  ],
}

class { 'php::globals':
  php_version => 'php73',
  rhscl_mode  => 'remi',
}
-> class { 'php':
  manage_repos => false,
  extensions => {
   mysqlnd => { },
  }
}

package { 'rh-mariadb101-mariadb-server':
  ensure => present,
}

service { 'rh-mariadb101-mariadb':
  ensure  => running,
  require => Package['rh-mariadb101-mariadb-server'],
}

file { '/opt/rh/httpd24/root/var/www/phpmyadmin':
  ensure  => directory,
  owner   => 'vagrant',
  group   => 'vagrant',
  require => Class['php'],
}

vcsrepo { '/opt/rh/httpd24/root/var/www/phpmyadmin':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/phpmyadmin/phpmyadmin.git',
    user     => 'vagrant',
    group    => 'vagrant',
    revision => 'STABLE',
    depth    => 1,
    require  => File['/opt/rh/httpd24/root/var/www/phpmyadmin'],
  }

exec { 'phpmyadmin-install':
  command     => '/usr/local/bin/composer update -d /opt/rh/httpd24/root/var/www/phpmyadmin --no-dev',
  creates     => '/opt/rh/httpd24/root/var/www/phpmyadmin/vendor/autoload.php',
  environment => 'COMPOSER_HOME=/home/vagrant',
  user        => 'vagrant',
  group       => 'vagrant',
  require     => Vcsrepo['/opt/rh/httpd24/root/var/www/phpmyadmin'],
}

