# = Class: monitoring_server::params
#
class monitoring_server::params {
    # elasticsearch configuration
    $es_instances = {
        'es' => {}
    }
    $es_config = {
        'network'    => {
            'host'       => '127.0.0.1'
        }
    }

    # logstash configuration
    $logstash_init_defaults = {
        'START' => 'true'
    }

}
