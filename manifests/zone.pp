define bind::zone (
    $zone_type,
    $domain          = '',
    $masters         = '',
    $allow_updates   = '',
    $allow_transfers = '',
    $dnssec          = false,
    $key_directory   = '',
    $ns_notify       = true,
    $also_notify     = '',
    $allow_notify    = '',
    $forwarders      = '',
    $forward         = '',
) {

    $cachedir = $::bind::cachedir

    if $domain == '' {
        $_domain = $name
    } else {
        $_domain = $domain
    }

    $has_zone_file = $zone_type ? {
        'master'    => true,
        'slave'     => true,
        'hint'      => true,
        'stub'      => true,
        default     => false,
    }

    if $has_zone_file {
        file { "${::bind::cachedir_abs}/${name}":
            ensure  => directory,
            owner   => $bind::bind_user,
            group   => $bind::bind_group,
            mode    => '0755',
            require => Class['::bind::config'],
        }
        
        if $zone_type != 'slave' {
            file { "${::bind::cachedir_abs}/${name}/${_domain}":
                ensure  => present,
                owner   => $bind::bind_user,
                group   => $bind::bind_group,
                mode    => '0644',
                replace => false,
                source  => 'puppet:///modules/bind/db.empty',
                audit   => [ content ],
            }
        }

        if $dnssec {
            exec { "dnssec-keygen-${name}":
                command => "/usr/local/bin/dnssec-init '${::bind::cachedir_abs}' '${name}' \
                            '${_domain}' '${key_directory}'",
                cwd     => $::bind::cachedir_abs,
                user    => $bind::bind_user,
                creates => "${::bind::cachedir_abs}/${name}/${_domain}.signed",
                timeout => 0, # crypto is hard
                require => [ File['/usr/local/bin/dnssec-init'],
                            File["${::bind::cachedir_abs}/${name}/${_domain}"] ],
            }

            file { "${::bind::cachedir_abs}/${name}/${_domain}.signed":
                owner => $bind::bind_user,
                group => $bind::bind_group,
                mode  => '0644',
                audit => [ content ],
            }
        }
    }

    file { "${::bind::confdir_abs}/zones/${name}.conf":
        ensure  => present,
        owner   => 'root',
        group   => $bind::bind_group,
        mode    => '0644',
        content => template('bind/zone.conf.erb'),
        notify  => Service['bind'],
        require => Class['::bind::config'],
    }

}
