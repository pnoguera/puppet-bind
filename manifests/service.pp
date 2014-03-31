class bind::service inherits bind {
    if ! ($service_ensure in [ 'running', 'stopped' ]) {
        fail('service_ensure parameter must be running or stopped')
    }
    
    if $service_manage == true {
        service { 'bind':
            ensure      => $service_ensure,
            enable      => $service_enable,
            name        => $service_name,
            hasrestart  => true,
            hasstatus   => true,
        }
    }
}
