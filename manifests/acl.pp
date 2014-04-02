define bind::acl (
    $addresses,
) {

    concat::fragment { "bind-acl-${name}":
        order   => '10',
        target  => "${bind::confdir_abs}/acls.conf",
        content => template('bind/acl.erb'),
    }

}
