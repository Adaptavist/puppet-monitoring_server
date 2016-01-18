# Monitoring server Module
[![Build Status](https://travis-ci.org/Adaptavist/puppet-monitoring_server.svg?branch=master)](https://travis-ci.org/Adaptavist/puppet-monitoring_server)

## Overview

The **Monitoring server** module provisions monitoring server with a set of monitoring tools. By default it will install Logstash, Elasticsearch, Kibana3, Grafana, Graphite and Collectd. Crowd authentication can be enabled by passing crowd credentials. 

## Configuration

This module is configured via Hiera.
Important when setting up crowd. If crowd integration is enabled, the default we assume grafana and graphite are sharing 
the same subdomain e.g. graphite.adaptavist.com and grafana.adaptavist.com. Then make sure you have enabled crowd sso for *.adaptavist.com. 

Other options are:

* create crowd user for grafana -> graphite connection and pass the credentials via grafana_graphite_crowd_user and grafana_graphite_crowd_pass.
* exclude authentication for all requests from grafana to graphite, set grafana_graphite_auth_disabled = true

Certificates can be passed to modules via 'puppet:///files/ssl' folder.

### include_kibana

If set to true(default), Logstash, Elasticsearch and Kibana is installed. 

#### Elasticsearch (ES) - https://github.com/Adaptavist/puppet-elasticsearch
  *es_instances    = hash of instances to run
  *es_version      = elasticsearch version, defaults to '1.1.0-1'
  *es_config       = configuration of ES, default sets 'host' => '127.0.0.1' 
  *es_install_java = should install java (true)
  *es_manage_repo  = indicates that the module will register repository to download package from (true)
  *es_repo_version = Repository version, '1.1',
  *es_host_port    = Listen host and port to access ES, 'http://192.168.0.1:9200'

#### Logstash - https://github.com/Adaptavist/puppet-logstash
  *logstash_init_defaults  = Init.d settings for logstash, 'START' => 'true'
  *logstash_manage_repo    = indicates that the module will register repository to download package from (true)
  *logstash_repo_version   = Repository version,'1.4'
  *logstash_status         = Status of logstash service, 'running'
  *logstash_config_file    = Logstash configuration file, 'puppet:///files/apache-elasticsearch.conf',

#### Kibana3 - https://github.com/Adaptavist/puppet-kibana3
  *kibana_k3_release         = kibana version, ('v3.0.1')
  *kibana_manage_ws          = manage webserver configuration via kibana3 module, (false)
  *kibana_config_es_server   = specify a specific elasticsearch host to kibana3, ('"+window.location.hostname+"')
  *kibana_config_es_port     = specify a specific elasticsearch port to kibana3, ('80/es')s
  *include_kibana_dashboards = if custom kibana dashboards should be loaded, (true)
  *kibana_dashboards_folder  = custom dashboards path, ('puppet:///files/kibana3')
  *kibana_servername         = apache servername to access kibana, ("kibana.${::fqdn}")

### include_collectd

If true(default), collectd server is installed. Make sure collectd version >= 5.2 is installed to support graphite integration.

####Collectd - https://stash.adaptavist.com/projects/PUP/repos/puppet-collectd/browse

  *collectd_listen_host   = Collectd listen host, ('0.0.0.0')
  *collectd_listen_port   = Collectd listen port, ('25826')
  *collectd_graphite      = Graphite integration, (true), requires collectd >=5.2
  *collectd_graphite_host = Graphite host, ('localhost')

### include_graphite

If enabled it will install and configure graphite.

 $graphite_servername = Graphite apache servername, ("graphite.${::fqdn}")

### include_grafana

If enabled it will install and configure grafana and integrate them with collectd and elasticsearch.

  $include_grafana = true,
  $grafana_version     = Prefered grafana version, ('1.8.1')
  $grafana_servername  = Grafana apache servername, ("grafana.${::fqdn}")
  
### Ownership setup
  
  *user  = User to own all installed apps and folders ('apache')
  *group = Group to own all installed apps and folders ('apache')

### Crowd authentication setup
  
Crowd access credentials needs to be passed to allow crowd integration

  *crowd_url = Crowd server url, (undef)
  *crowd_app = Crowd application name, (undef)
  *crowd_password = Password to access crowd, (undef)


## Dependencies

Apache, Logstash, Kibana3, Elasticsearch, Collectd, Grafana, Graphite
See Modulefile for more details.
