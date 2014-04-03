class bind (
    $chroot_enable      = $bind::params::chroot_enable,
    $chroot_dir         = $bind::params::chroot_dir,
    $confdir            = $bind::params::confdir,
    $cachedir           = $bind::params::cachedir,
    $bind_user          = $bind::params::bind_user,
    $bind_group         = $bind::params::bind_group,
    $dnssec             = $bind::params::dnssec,
    $forwarders         = $bind::params::forwarders,
    $package_name       = $bind::params::package_name,
    $package_ensure     = $bind::params::package_ensure,
    $service_enable     = $bind::params::service_enable,
    $service_ensure     = $bind::params::service_ensure,
    $service_manage     = $bind::params::service_manage,
    $service_name       = $bind::params::service_name,
    $version            = $bind::params::version,
) inherits bind::params {

    validate_bool($chroot_enable)
    validate_absolute_path($chroot_dir)
    validate_absolute_path($confdir)
    validate_absolute_path($cachedir)
    validate_string($bind_user)
    validate_string($bind_group)
    validate_bool($dnssec)
    validate_array($forwarders)
    validate_string($package_name)
    validate_string($package_ensure)
    validate_bool($service_enable)
    validate_string($service_ensure)
    validate_bool($service_manage)
    validate_string($service_name)
    validate_string($version)

    $confdir_abs = $chroot_enable ? {
        true        => "${chroot_dir}/${confdir}",
        defaults    => $confdir, 
    }

    $cachedir_abs = $chroot_enable ? {
        true        => "${chroot_dir}/${cachedir}",
        defaults    => $cachedir, 
    }

    anchor { 'bind::begin': } ->
    class { '::bind::install': } ->
    class { '::bind::config': } ~>
    class { '::bind::service': } ->
    anchor { 'bind::end': }
}
