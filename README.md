bind
====

## Description
Control BIND name servers and zones
=======
Overview
--------

The BIND module provides an interface for managing a BIND name server, including installation of software, configuration of the server, creation of keys, and definitions for zones.

Module Description
------------------

BIND automates configuration and operation of a BIND DNS server.

Setup
-----

**What BIND affects:**

* package installation and service control for BIND
* configuration of the server, zones, acls, keys, and views
* creation of TSIG and DNSSEC keys
* creation of chroot environment if needed

###Getting started

To begin using the BIND module with default parameters, declare the class

    class { 'bind': }

Puppet code that uses anything from the BIND module requires that the core bind classes be declared.

###bind

`bind` provides a few parameters that control server-level configuration parameters in the `named.conf` file, and also defines the overall structure of DNS service on the node.

    class { 'bind':
        chroot_enable   => true,
        chroot_dir      => '/var/chroot/bind9',
        confdir         => '/etc/bind',
        cachedir        => '/var/lib/bind',
        forwarders      => [
            '8.8.8.8',
            '8.8.4.4',
        ],
        dnssec          => true,
        version         => 'Controlled by Puppet',
    }

Puppet will manage the entire `named.conf` file and its includes.  Most parameters are set to a fixed value, but the server's upstream resolvers are controlled using `forwarders`, enabling of DNSSec signature validation is controlled using `dnssec`, and the reported version is controlled using `version`.  It is unlikely that you will need to define an alternate value for `confdir` or `cachedir`.

###bind::key

Creates a TSIG key file.  Only the `secret` parameter is required, but it is recommended to explicitly supply the `algorithm` as well.  The key file will be stored in `${::bind::confdir}/keys` with a filename derived from the title of the `bind::key` declaration.

    bind::key { 'local-update':
        algorithm => 'hmac-sha256',
        secret    => '012345678901345678901234567890123456789=',
        owner     => 'root',
        group     => 'bind',
    }

###bind::acl

Declares an acl in the server's configuration.  The acl's name is the title of the `bind::acl` declaration.

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

###bind::zone

Declares a zone in the server's configuration.  The corresponding zone file will be created if it is absent, but any existing file will not be overwritten.  Only the `zone_type` is required.  If `domain` is unspecified, the title of the `bind::zone` declaration will be used as the domain.

A master zone with DNSSec disabled which allows updates using a TSIG key and zone transfers to servers matching an acl:

    bind::zone { 'example.com-internal':
        zone_type       => 'master',
        domain          => 'example.com',
        allow_updates   => [ 'key local-update', ],
        allow_transfers => [ 'secondary-dns', ],
        ns_notify       => true,
        dnssec          => false,
    }

A master zone with DNSSec enabled which allows updates using a TSIG key and zone transfers to servers matching an acl:

    bind::zone { 'example.com-external':
        zone_type       => 'master',
        domain          => 'example.com',
        allow_updates   => [ 'key local-update', ],
        allow_transfers => [ 'secondary-dns', ],
	ns_notify       => true,
        dnssec          => true,
	key_directory   => '/var/cache/bind/example.com',
    }

A slave zone which allows notifications from servers matched by IP:

    bind::zone { 'example.net':
        zone_type    => 'slave',
        masters      => [ '198.0.2.2' ],
        allow_notify => [ '192.0.2.2' ],
        ns_notify    => false,
    }

A forward zone:

    bind::zone { 'example.org':
        zone_type  => 'forward',
        forwarders => [ '10.0.2.4', ],
        forward    => 'only',
    }

###bind::view

Declares a view in the BIND configuration.  There must be at least one view declaration.

A common use for views is to use a single dual-homed nameserver as a resolver on a private network and an authoritative non-resolving nameserver on the Internet.  Furthermore, the Internet-facing and private network-facing views may present different authoritative results for a domain.  Given a BIND server connected to the internet with the address 198.0.2.2 and connected to a private network with the address 10.0.2.2, here are the `bind::view` declarations that would create this configuration:

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

In this scenario, the example.com domain has two separate zones that are presented in each of the `internet` and `private` views.  These two zones are independent, and TSIG-signed updates to example.com must be made to either 198.0.2.2 or 10.0.2.2, to change the `internet` or `private` views of this domain.  Updates to `example.net` may be made via either address, since the zone is included in both views.

Another use for views is to control access to the DNS server's services.  In this example, service is restricted to a specific set of client address ranges, and queries for the `example.org` domain are handled using a declared zone (see `bind::zone` declaration for `example.org` above):

    bind::view { 'clients':
        recursion     => true,
        match_clients => [
            '10.10.0.0/24',
            '10.100.0.0/24',
        ],
        zones         => [
            'example.org',
        ],
    }

###dns_rr

Declares a resource record.  For exampmle:

    dns_rr { 'IN/A/www.example.com':
        ensure  => present,
        rrdata  => [ '172.16.32.10', '172.16.32.11' ],
        ttl     => 86400,
        zone    => 'example.com',
        server  => 'ns.example.com',
        keyname => 'local',
        hmac    => 'hmac-sha1',
        secret  => 'aLE5LA=='
    }

This resource declaration will result in address records with the addresses 172.16.32.10 and 172.16.32.11 (`rrdata`), a TTL of 86400 (`ttl`) in the zone example.com (`zone`).  Any updates necessary to create, update, or destroy these records are authenticated using a TSIG key named 'local' (`keyname`) of the given type (`hmac`) with the given `secret`.

`rrdata` is required, and may be a scalar value or an array of scalar values whose format conform to the type of DNS resource record being created.  `rrdata` is an ensurable property and changes will be reflected in DNS.

`ttl` defaults to 43200 and need not be specified.  `ttl` is an ensurable property and changes will be reflected in DNS.

`zone` is not required, and generally not needed.  It is only necessary to specify the zone to be updated if the target nameserver has the record in multiple zones, e.g. the NS records of a zone whose parent zone is served by the same nameserver.

`server` defaults to "localhost" and need not be specified.  The value may be either a hostname or IP address.

`keyname` defaults to "update" and need not be specified.  This parameter specifies the name of a TSIG key to be used to authenticate the update.  The resource only uses a TSIG key if a `secret` is specified.

`hmac` defaults to "hmac-sha1" and need not be specified.  This parameter specifies the algorithm of the TSIG key to be used to authenticate the update.  The resource only uses a TSIG key if a `secret` is specified.

`secret` is optional.  This parameter specifies the encoded cryptographic secret of the TSIG key to be used to authenticate the update.  If no `secret` is specified, then the update will not use TSIG authentication.
