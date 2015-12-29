require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint'

PuppetLint.configuration.send('disable_puppet_url_without_modules')
PuppetLint.configuration.send('disable_quoted_booleans')
PuppetLint.configuration.send('disable_arrow_alignment')
task :default => [:spec, :lint]