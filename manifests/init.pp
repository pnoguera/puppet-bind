class bind (
    $package            = $bind::params::package_name,
    $package_ensure     = $bind::params::package_ensure,
    $confdir            = $bind::params::confdir,
    $cachedir           = $bind::params::cachedir,
    $bind_service       = $bind::params::bind_service,
    $bind_user          = $bind::params::bind_user,
    $bind_group         = $bind::params::bind_group,
    $forwarders         = '',
    $dnssec             = false,
    $version            = '',
) inherits bind::params {

    $auth_nxdomain = false

    package { 'bind':
        ensure  => $package_ensure,
        name    => $package_name,
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

    service { $bind::params::bind_service:
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['bind'],
    }

    File {
        ensure  => present,
        owner   => 'root',
        group   => $bind_group,
        mode    => 0644,
    }

    file { [ $confdir, "${confdir}/zones" ]:
        ensure  => directory,
        mode    => '2755',
        purge   => true,
        recurse => true,
        require => Package['bind'],
    }

    file { "${confdir}/named.conf":
        content => template('bind/named.conf.erb'),
        notify  => Service[$bind_service],
        require => Package['bind'],
    }

    file { "${confdir}/keys":
        ensure  => directory,
        mode    => '0755',
        require => Package['bind'],
    }

    file { "${confdir}/named.conf.local":
        replace => false,
        require => Package['bind'],
    }

    concat { [
        "${confdir}/acls.conf",
        "${confdir}/keys.conf",
        "${confdir}/views.conf",
        ]:
        owner   => 'root',
        group   => $bind_group,
        mode    => '0644',
        notify  => Service[$bind_service],
        require => Package['bind'],
    }

    concat::fragment { 'named-acls-header':
        order   => '00',
        target  => "${confdir}/acls.conf",
        content => "# This file is managed by puppet - changes will be lost\n",
    }

    concat::fragment { 'named-keys-header':
        order   => '00',
        target  => "${confdir}/keys.conf",
        content => "# This file is managed by puppet - changes will be lost\n",
    }

    concat::fragment { 'named-keys-rndc':
        order   => '99',
        target  => "${confdir}/keys.conf",
        content => "#include \"${confdir}/rndc.key\"\n",
    }

    concat::fragment { 'named-views-header':
        order   => '00',
        target  => "${confdir}/views.conf",
        content => "# This file is managed by puppet - changes will be lost\n",
    }
}
