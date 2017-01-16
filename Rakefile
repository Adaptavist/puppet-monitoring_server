require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

PuppetLint.configuration.send('disable_quoted_booleans')
PuppetLint.configuration.send('disable_arrow_alignment')
PuppetLint.configuration.send('disable_puppet_url_without_modules')
ENV['STRICT_VARIABLES']='no'
task :default => [:spec, :lint, :syntax]
