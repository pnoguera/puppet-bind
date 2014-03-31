class bind::install inherits bind {
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
}
