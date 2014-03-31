class bind::params (
    $dnssec         = false,
    $forwarders     = '',
    $package_ensure = 'latest',
    $service_enable = true,
    $service_ensure = 'running',
    $service_manage = true,
    $version        = '',
){

    case $::osfamily {
        'Debian': {
            $bind_user      = 'bind'
            $bind_group     = 'bind'
            $package_name   = 'bind9'
            $confdir        = '/etc/bind'
            $cachedir       = '/var/cache/bind'
            $service_name   = 'bind9'

        }
        default: {
            fail("Operating system is not supported ${::osfamily}")
        }
    }

}
