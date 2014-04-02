class bind::config inherits bind {

    #$auth_nxdomain = false
    $defaults = $chroot_enable ? {
        true      => "RESOLVCONF=no\nOPTIONS=\"-u bind -t ${chroot_dir}\"\n",
        defaults  => "RESOLVCONF=no\nOPTIONS=\"-u bind\n"
    }

    File {
        ensure  => present,
        owner   => 'root',
        group   => $bind_group,
        mode    => 0644,
    }

    file { "/etc/default/${service_name}":
        ensure  => 'present',
        content => $defaults
    }

    file { [
        "${confdir_abs}/bind.keys",
        "${confdir_abs}/db.empty",
        "${confdir_abs}/db.local",
        "${confdir_abs}/db.root",
        "${confdir_abs}/db.0",
        "${confdir_abs}/db.127",
        "${confdir_abs}/db.255",
        #"${confdir_abs}/acls.conf",
        #"${confdir_abs}/keys.conf",
        #"${confdir_abs}/views.conf",
        "${confdir_abs}/named.conf.default-zones",
        "${confdir_abs}/rndc.key",
        "${confdir_abs}/zones.rfc1918",
        ]:
        ensure  => present,
    }

    if $chroot_enable == true {
        file { $confdir:
            ensure  => 'link',
            target  => $confdir_abs,
        }

        file { $cachedir:
            ensure  => 'link',
            target  => $cachedir_abs,
        }
    }
    
    file { [ $confdir_abs, "${confdir_abs}/zones" ]:
        ensure  => directory,
        mode    => '2755',
        purge   => true,
        recurse => true,
    }

    file { "${confdir_abs}/named.conf":
        content => template('bind/named.conf.erb'),
    }

    file { "${confdir_abs}/keys":
        ensure  => directory,
        mode    => '0755',
    }

    file { "${confdir_abs}/named.conf.local":
        replace => false,
    }

    concat { [
        "${confdir_abs}/acls.conf",
        "${confdir_abs}/keys.conf",
        "${confdir_abs}/views.conf",
        ]:
        owner   => 'root',
        group   => $bind_group,
        mode    => '0644',
    }

    concat::fragment { 'named-acls-header':
        order   => '00',
        target  => "${confdir_abs}/acls.conf",
        content => "# This file is managed by puppet - changes will be lost\n",
    }

    concat::fragment { 'named-keys-header':
        order   => '00',
        target  => "${confdir_abs}/keys.conf",
        content => "# This file is managed by puppet - changes will be lost\n",
    }

    concat::fragment { 'named-keys-rndc':
        order   => '99',
        target  => "${confdir_abs}/keys.conf",
        content => "#include \"${confdir}/rndc.key\"\n",
    }

    concat::fragment { 'named-views-header':
        order   => '00',
        target  => "${confdir_abs}/views.conf",
        content => "# This file is managed by puppet - changes will be lost\n",
    }
}
