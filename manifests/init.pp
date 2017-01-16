class monitoring_server(
  $include_kibana  = true,
  $es_instances    = $monitoring_server::params::es_instances,
  $es_version      = '1.2.1-1',
  $es_config       = $monitoring_server::params::es_config,
  $es_install_java = true,
  $es_manage_repo  = true,
  $es_repo_version = '1.2',
  $es_host_port    = 'http://localhost:9200',
  $logstash_init_defaults  = $monitoring_server::params::logstash_init_defaults,
  $logstash_manage_repo    = true,
  $logstash_repo_version   = '1.4',
  $logstash_status         = 'running',
  $logstash_config_file    = 'puppet:///files/apache-elasticsearch.conf',
  $kibana_k3_release         = 'v3.0.1',
  $kibana_manage_ws          = false,
  $kibana_config_es_server   = '"+window.location.hostname+"',
  $kibana_config_es_port     = '80/es',
  $include_kibana_dashboards = true,
  $kibana_dashboards_folder  = 'puppet:///files/kibana3',
  $kibana_servername         = "kibana.${::fqdn}",
  $include_collectd       = true,
  $collectd_listen_host   = '0.0.0.0',
  $collectd_listen_port   = '25826',
  $collectd_graphite      = true,
  $collectd_graphite_host = 'localhost',
  $include_grafana = true,
  $include_graphite = true,
  $graphite_servername = "graphite.${::fqdn}",
  $grafana_version     = '1.8.1',
  $grafana_servername  = "grafana.${::fqdn}",
  $grafana_graphite_auth_disabled = undef,
  $grafana_graphite_crowd_user = undef,
  $grafana_graphite_crowd_pass = undef,
  $user  = 'apache',
  $group = 'apache',
  $crowd_url = undef,
  $crowd_app = undef,
  $crowd_password = undef,
  $apache_version = 2.4,
  ) inherits monitoring_server::params {

    class {'apache':
      default_vhost => false,
      apache_version => $apache_version
    }

    if $crowd_url {
      $base_directories = {
        path => '/',
        provider => 'location',
        auth_basic_provider => 'crowd',
        auth_type => 'basic',
        auth_name => 'Crowd Credentials for Monitoring',
      }

      if $grafana_graphite_auth_disabled == true {
        $custom_directories = {
          auth_require => 'valid-user',
          allow => 'from env=allowed',
          order => 'deny,allow',
          deny => 'from all',
          custom_fragment => "CrowdCreateSSO On
      CrowdAppName ${crowd_app}
      CrowdAppPassword ${crowd_password}
      CrowdURL ${crowd_url}
      Satisfy any
      SetEnvIfNoCase Referer ${grafana_servername} allowed
      "
          }
      } else {
        $custom_directories = {
          custom_fragment => "<LimitExcept OPTIONS>
        Require valid-user
      </LimitExcept>
      CrowdCreateSSO On
      CrowdAppName ${crowd_app}
      CrowdAppPassword ${crowd_password}
      CrowdURL ${crowd_url}"
          }
      }

      $directories = merge($base_directories, $custom_directories)

      package {'mod_authnz_crowd':
      }

      apache::mod {'authnz_crowd':
        require => Package['mod_authnz_crowd'],
      }
    } else {
      $directories = {
        path => '/',
        provider => 'location',
      }
    }

    if ($include_kibana == true){
      class {'elasticsearch' :
        version      => $es_version,
        manage_repo  => $es_manage_repo,
        repo_version => $es_repo_version,
        java_install => $es_install_java,
        config       => $es_config,
      }
      create_resources('elasticsearch::instance',  $es_instances)

      class {'logstash' :
        manage_repo   => $logstash_manage_repo,
        repo_version  => $logstash_repo_version,
        status        => $logstash_status,
        init_defaults => $logstash_init_defaults,
        require       => Class['elasticsearch'],
      }

      logstash::configfile {'logstash-config':
        source => $logstash_config_file,
      }

      class {'kibana3' :
        k3_release       => $kibana_k3_release,
        manage_ws        => $kibana_manage_ws,
        k3_folder_owner  => $user,
        config_es_server => $kibana_config_es_server,
        config_es_port   => $kibana_config_es_port,
      }
      if ($include_kibana_dashboards == true){
        file { '/opt/kibana3/src/app/dashboards':
          source  => $kibana_dashboards_folder,
          recurse => 'true',
          require => Class['kibana3']
        }
      }

      apache::vhost {
        'kibana3':
          servername        => $kibana_servername,
          docroot           => "${::kibana3::k3_install_folder}/src",
          port              => 80,
          docroot_owner     => $user,
          docroot_group     => $group,
          directories       => $directories,
          require           => Vcsrepo['/opt/kibana3'],
          proxy_pass        => [{
                              path => '/es',
                              url  => $es_host_port,
                            }],
          access_log_format => '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %% %T %D %{XMETRIX-COMBINED}o',
      }
      $elasticsearch_datasource = {
        'elasticsearch' => {
            'type'      => 'elasticsearch',
            'url'       => "http://${grafana_servername}/es",
            'index'     => 'grafana-dash',
            'grafanaDB' => 'true',
          }
      }
    } else {
      $elasticsearch_datasource = {}
    }

    if ($include_collectd == true){
      class {'collectd::server':
        listen_host    => $collectd_listen_host,
        listen_port    => $collectd_listen_port,
        write_graphite => $collectd_graphite,
        graphite_host  => $collectd_graphite_host,
      }

      include collectd::client
      include collectd::plugin::cpu
      include collectd::plugin::disk
      include collectd::plugin::df
      include collectd::plugin::interface
      include collectd::plugin::load
      include collectd::plugin::memory
      include collectd::plugin::users
      include collectd::plugin::tcpconns
    }

    if($include_graphite == true){
      class {'graphite':
        owner => $user,
        group => $group,
      }

      include apache::mod::wsgi

      # Note that Graphite uses Django and has to be in the root context path
      # it is not possible to put graphite on anything other than /
      # (well without hacking at the code and Dango config or using mod_html)
      apache::vhost {'graphite-web':
        servername                  => $graphite_servername,
        port                        => 80,
        docroot                     => '/usr/share/graphite/webapp',
        directories                 => $directories,
        headers                     => [
          "set Access-Control-Allow-Origin 'http://${grafana_servername}'",
          'set Access-Control-Allow-Methods "GET, OPTIONS"',
          'set Access-Control-Allow-Headers "origin, authorization, accept"',
          'set Access-Control-Allow-Credentials true',
        ],
        wsgi_import_script          => '/usr/share/graphite/graphite-web.wsgi',
        wsgi_import_script_options  => {
          process-group     => '%{GLOBAL}',
          application-group => '%{GLOBAL}'
        },
        wsgi_script_aliases         => {
          '/' => '/usr/share/graphite/graphite-web.wsgi'
        },
        require                     => Class['graphite'],
      }

      if ($grafana_graphite_crowd_user != undef){
        $graphite_crowd_credentials="${grafana_graphite_crowd_user}:${grafana_graphite_crowd_pass}@"
      } else {
        $graphite_crowd_credentials=''
      }

      $graphite_datasource = {
        'graphite' => {
            'type'    => 'graphite',
            'url'     => "http://${graphite_crowd_credentials}${graphite_servername}",
            'default' => 'true'
          }
        }
    }

    if($include_grafana == true){
      include apache::mod::headers
      $grafana_datasources = merge($graphite_datasource, $elasticsearch_datasource)

      class { 'grafana':
        install_dir   => '/opt',
        grafana_user  => $user,
        grafana_group => $group,
        datasources   => $grafana_datasources,
      } ->
      apache::vhost {
        'grafana':
          servername    => $grafana_servername,
          docroot       => '/opt/grafana',
          port          => 80,
          docroot_owner => $user,
          docroot_group => $group,
          directories                 => $directories,
          proxy_pass    => [{
                            path => '/es',
                            url  => $es_host_port,
                            }],
          headers       => [
          "set Access-Control-Allow-Origin 'http://${graphite_servername}'",
          'set Access-Control-Allow-Methods "GET, OPTIONS, POST, PUT, DELETE"',
          'set Access-Control-Allow-Headers "origin, authorization, accept"',
          'set Access-Control-Allow-Credentials true',
        ],
          access_log_format => '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %% %T %D %{XMETRIX-COMBINED}o',
      }
    }
}
