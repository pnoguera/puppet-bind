class bind::install inherits bind {

    package { 'bind':
        ensure  => $package_ensure,
        name    => $package_name,
    }

    if ! defined(Package['dnsutils']) {
        package { 'dnsutils' :
            ensure  => 'present',
        }
    }

    if $dnssec {
        file { '/usr/local/bin/dnssec-init':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
            source => 'puppet:///modules/bind/dnssec-init',
        }
    }

    if $chroot_enable == true {

        exec { 'Stop bind':
            command     => "/etc/init.d/${service_name} stop",
            refreshonly => true,
            subscribe   => Package['bind']
        }

        File {
            ensure  => directory,
            owner   => $bind_owner,
            group   => $bind_group,
            mode    => '770',
            #require => Package['bind']
            #require => Exec['Stop bind'],
        }

        Package['bind'] ->

        file { [
            '/var/chroot',
            $chroot_dir,
            "${chroot_dir}/etc",
            "${chroot_dir}/dev",
            "${chroot_dir}/var/",
            "${chroot_dir}/var/run",
            "${chroot_dir}/var/cache",
            "${chroot_dir}/var/run/named",
            ]:
        } ->


        exec { "mv ${confdir} ${confdir_abs}":
            unless  => "test -d ${confdir_abs}",
        } ->

        exec { "mv ${cachedir} ${cachedir_abs}":
            unless  => "test -d ${cachedir_abs}",
        } 

        exec { "mknod ${chroot_dir}/dev/null c 1 3":
            unless  => "test -c ${chroot_dir}/dev/null",
            require => File["${chroot_dir}/dev"],
        } ->

        exec { "mknod ${chroot_dir}/dev/random c 1 8":
            unless => "test -c ${chroot_dir}/dev/random",
            require => File["${chroot_dir}/dev"],
        } ->

        file { [
            "${chroot_dir}/dev/random",
            "${chroot_dir}/dev/null"
        ]:
            ensure  => 'present',
            mode    => '660',
        }

        file_line { 'bind9 init file':
            path  => "/etc/init.d/${service_name}",
            match => 'PIDFILE=',
            line  => "PIDFILE=${chroot_dir}/var/run/named/named.pid",
            require => Package['bind']
        }

        file { '/etc/rsyslog.d/bind-chroot.conf':
            ensure  => 'present',
            content => '$AddUnixListenSocket /var/bind9/chroot/dev/log',
            require => Package['bind']
        } ~>

        exec { '/etc/init.d/rsyslog restart':
            refreshonly => true
        }
    }
}
