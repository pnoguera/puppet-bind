define bind::key (
    $secret,
    $algorithm = 'hmac-sha256',
    $owner     = 'root',
    $group     = $bind::bind_group,
) {
    file { "${bind::confdir}/keys/${name}":
        ensure  => present,
        owner   => $owner,
        group   => $group,
        mode    => '0640',
        content => template('bind/key.conf.erb'),
        notify  => Service['bind'],
        require => Package['bind'],
    }
    concat::fragment { "bind-key-${name}":
        order   => '10',
        target  => "${bind::confdir}/keys.conf",
        content => "include \"${bind::confdir}/keys/${name}\";\n",
    }
}
