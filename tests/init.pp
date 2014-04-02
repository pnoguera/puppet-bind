## Smoke test
Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

class { 'bind':
    chroot_enable   => true,
    chroot_dir      => '/var/chroot/bind9',
#    confdir         => '/etc/bind',
#    cachedir        => '/var/lib/bind',
    forwarders      => [
        '8.8.8.8',
        '8.8.4.4',
    ],
    dnssec          => false,
    version         => 'Controlled by Puppet',
}

/*
class { 'bind':
    confdir    => '/etc/bind',
    cachedir   => '/var/lib/bind',
    forwarders => [
        '8.8.8.8',
        '8.8.4.4',
    ],
    dnssec     => true,
    version    => 'Controlled by Puppet',
}*/

bind::key { 'local-update':
    algorithm => 'hmac-sha256',
    secret    => 'dGVzdGluZwo=',
    owner     => 'root',
    group     => 'bind',
}

bind::acl { 'rfc1918':
    addresses => [
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
    ]
}

bind::acl { 'secondary-dns':
    addresses => '192.0.2.4/32',
}

bind::zone { 'example.com-internal':
    zone_type       => 'master',
    domain          => 'example.com',
    allow_updates   => [ 'key local-update', ],
    allow_transfers => [ 'secondary-dns', ],
    ns_notify       => true,
    dnssec          => false,
}

bind::zone { 'example.net':
    zone_type       => 'master',
    domain          => 'example.net',
    allow_updates   => [ 'key local-update', ],
    allow_transfers => [ 'secondary-dns', ],
    ns_notify       => true,
    dnssec          => false,
}

bind::zone { 'example.com-external':
    zone_type       => 'master',
    domain          => 'example.com',
    allow_updates   => [ 'key local-update', ],
    allow_transfers => [ 'secondary-dns', ],
    ns_notify       => true,
    #dnssec          => true,
    #key_directory   => '/var/lib/bind/example.com-external',
}


bind::view { 'internet':
    recursion          => false,
    match_destinations => [ '198.0.2.2', ],
    zones              => [ 'example.net', 'example.com-external', ],
}

bind::view { 'private':
    recursion          => true,
    match_destinations => [ '10.0.2.2', ],
    zones              => [ 'example.net', 'example.com-internal', ],
}
