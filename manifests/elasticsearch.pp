# = Class: newrelic_plugins::elasticsearch
#
# This class installs/configures/manages New Relic's Elasticsearch Plugin.
# Only supported on Debian-derived and Red Hat-derived OSes.
#
# == Parameters:
#
# $license_key::     License Key for your New Relic account
#
# $install_path::    Install Path for New Relic Elasticsearch Plugin.
#                    Any downloaded files will be placed here.
#                    The plugin will be installed within this
#                    directory at `newrelic_elasticsearch_plugin`.
#
# $user::            User to run as
#
# $version::         New Relic Elasticsearch Plugin Version.
#                    Currently defaults to the latest version.
#
#
# == Requires:
#
#   puppetlabs/stdlib
#
# == Sample Usage:
#
#   class { 'newrelic_plugins::elasticsearch':
#     license_key    => 'NEW_RELIC_LICENSE_KEY',
#     install_path   => '/path/to/plugin',
#     user           => 'newrelic'
#   }
#
class newrelic_plugins::elasticsearch (
    $license_key,
    $install_path,
    $user,
    $version = $newrelic_plugins::params::elasticsearch_version
) inherits params {

  include stdlib

  # verify java is installed
#  newrelic_plugins::resource::verify_java { 'Elasticsearch Plugin': }

  # verify attributes
  validate_absolute_path($install_path)
  validate_string($user)
  validate_string($version)

  # verify license_key
  newrelic_plugins::resource::verify_license_key { 'Elasticsearch Plugin: Verify New Relic License Key':
    license_key => $license_key
  }

  $plugin_path = "${install_path}/newrelic_elasticsearch_plugin"

  # install plugin
  newrelic_plugins::resource::install_plugin { 'newrelic_elasticsearch_plugin':
    install_path => $install_path,
    plugin_path  => $plugin_path,
    download_url => "${$newrelic_plugins::params::elasticsearch_download_baseurl}/${version}/newrelic-elasticsearch-plugin-${version}.tar.gz",
    version      => $version,
    user         => $user
  }

  # newrelic.json template
  file { "${plugin_path}/config/newrelic.json":
    ensure  => file,
    content => template('newrelic_plugins/elasticsearch/newrelic.json.erb'),
    owner   => $user,
    notify  => Service['newrelic-elasticsearch-plugin']
  }

  # plugin.json template
  file { "${plugin_path}/config/plugin.json":
    ensure  => file,
    content => template('newrelic_plugins/elasticsearch/plugin.json'),
    owner   => $user,
    notify  => Service['newrelic-elasticsearch-plugin']
  }

  # install init.d script and start service
  newrelic_plugins::resource::plugin_service { 'newrelic-elasticsearch-plugin':
    daemon         => 'plugin.jar',
    daemon_dir     => $plugin_path,
    plugin_name    => 'Elasticsearch',
    plugin_version => $version,
    user           => $user,
    run_command    => "java ${java_options} -jar",
    service_name   => 'newrelic-elasticsearch-plugin'
  }

  # ordering
#  Newrelic_plugins::Resource::Verify_java['Elasticsearch Plugin']
#  ->
  Newrelic_plugins::Resource::Verify_license_key['Elasticsearch Plugin: Verify New Relic License Key']
  ->
  Newrelic_plugins::Resource::Install_plugin['newrelic_elasticsearch_plugin']
  ->
  File["${plugin_path}/config/newrelic.json"]
  ->
  File["${plugin_path}/config/plugin.json"]
  ->
  Newrelic_plugins::Resource::Plugin_service['newrelic-elasticsearch-plugin']
}

