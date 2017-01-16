require 'spec_helper'
 
os = 'CentOS'
os_release = '6.6' 
os_family = "RedHat"
install_dir="/opt"
mod_crowd_package = "mod_authnz_crowd"
kibana_k3_release = "v3.0.1"
kibana_manage_ws = false
user = "apache"
group = "aache"
kibana_config_es_server = '"+window.location.hostname+"'
kibana_config_es_port     = "80/es"
daatsources = {"elasticsearch"=>{"type"=>"elasticsearch", "url"=>"http://grafana.monitoring.example.com/es", "index"=>"grafana-dash", "grafanaDB"=>"true"}}
apache_version = '2.4'
describe 'monitoring_server', :type => 'class' do

    context "Should install package, create vhosts and include classes" do
      let(:params) { {
        :include_kibana => true,
        :include_grafana => true,
        :include_graphite => false,
        :grafana_graphite_auth_disabled => true,
        :grafana_graphite_crowd_user => "crowd_user",
        :grafana_graphite_crowd_pass => "crowd_pass",
        :crowd_url => "http://crowd.example.com/crowd",
        :crowd_app => "crowd_app",
        :crowd_password => "crowd_pass",
        :es_install_java => false,
        :kibana_config_es_port => "#{kibana_config_es_port}",
        :kibana_config_es_server => "#{kibana_config_es_server}",
        :kibana_manage_ws => "#{kibana_manage_ws}",
        :kibana_k3_release => "#{kibana_k3_release}",
        :user => "#{user}",
        :group => "#{group}",
        :apache_version => apache_version
      } }
      let(:facts) { {
        :osfamily => "#{os_family}",
        :operatingsystemrelease => "#{os_release}",
        :operatingsystemmajrelease => '7',
        :operatingsystem => "#{os}",
        :concat_basedir => '/tmp',
        :kernel => 'Linux',
      } }
      let(:node) { 'monitoring.example.com' }


      it do
        should contain_package("#{mod_crowd_package}")
        should contain_apache__mod("authnz_crowd").with(
          'require' => "Package[#{mod_crowd_package}]"
        )
      end

      it do
        should contain_class("kibana3").with(
          'k3_release'       => "#{kibana_k3_release}",
          'manage_ws'        => "#{kibana_manage_ws}",
          'k3_folder_owner'  => "#{user}",
          'config_es_server' => "#{kibana_config_es_server}",
          'config_es_port'   => "#{kibana_config_es_port}",
        )
        should contain_apache__vhost('kibana3')
      end

      it do
        should contain_class("grafana").with(
          'install_dir'   => "#{install_dir}",
          'grafana_user'  => "#{user}",
          'grafana_group' => "#{group}",
          'datasources'   => "#{daatsources}",
        )
        should contain_apache__vhost('grafana')
      end
    
    end
end
