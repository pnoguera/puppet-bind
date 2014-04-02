define bind::view (
    $match_clients      = 'any',
    $match_destinations = '',
    $zones              = [],
    $recursion          = true,
) {

    $confdir = $bind::confdir

    concat::fragment { "bind-view-${name}":
        order   => '10',
        target  => "${bind::confdir_abs}/views.conf",
        content => template('bind/view.erb'),
    }
}
