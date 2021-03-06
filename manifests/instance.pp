define logstash::instance (
  $ensure      = present,
  $java_opts   = '-Xms256m -Xmx256m',
  $input_file  = "puppet:///${module_name}/${name}-default-input",
  $filter_file = "puppet:///${module_name}/${name}-default-filter",
  $output_file = "puppet:///${module_name}/${name}-default-output",
) {

  $service_ensure = $ensure ? { present => 'running', default => 'stopped' }
  $service_enable = $ensure ? { present => true, default => false }

  concat {"${logstash::etc}/${name}.conf":
    owner   => $logstash::user,
    group   => $logstash::group,
    mode    => '0644',
    force   => true,
    notify  => Service["logstash-${name}"],
  }

  concat::fragment {"input-${name}":
    ensure => $ensure,
    target => "${logstash::etc}/${name}.conf",
    source => $input_file,
    order  => 01,
  }

  concat::fragment {"filter-${name}":
    ensure => $ensure,
    target => "${logstash::etc}/${name}.conf",
    source => $filter_file,
    order  => 02,
  }

  concat::fragment {"output-${name}":
    ensure => $ensure,
    target => "${logstash::etc}/${name}.conf",
    source => $output_file,
    order  => 03,
  }

  logstash::initscript {$name:
    ensure    => $ensure,
    java_opts => $java_opts,
  }

  service {"logstash-${name}":
    ensure    => $service_ensure,
    hasstatus => true,
    enable    => $service_enable,
    require   => [
      Package['logstash'],
      File[$logstash::log],
    ],
  }

  if $ensure == 'present' {
    Logstash::Initscript[$name] -> Service["logstash-${name}"]
  } else {
    Service["logstash-${name}"] -> Logstash::Initscript[$name]
  }

}

