class bind::config inherits bind {

    #$auth_nxdomain = false
    
    File {
        ensure  => present,
        owner   => 'root',
        group   => $bind_group,
        mode    => 0644,
    }

    file { [
        "${confdir}/bind.keys",
        "${confdir}/db.empty",
        "${confdir}/db.local",
        "${confdir}/db.root",
        "${confdir}/db.0",
        "${confdir}/db.127",
        "${confdir}/db.255",
        "${confdir}/named.conf.default-zones",
        "${confdir}/rndc.key",
        "${confdir}/zones.rfc1918",
        ]:
        ensure  => present,
        require => Package['bind'],
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
        notify  => Service['bind'],
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
        notify  => Service['bind'],
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
