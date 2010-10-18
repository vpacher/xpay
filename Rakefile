require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'bundler'

require File.expand_path('../lib/xpay/version', __FILE__)

namespace :test do
  Rake::TestTask.new(:all) do |test|
    test.libs << 'lib' << 'test'
    test.pattern   = 'test/{functional,unit}/**/test_*.rb'
  end
end
task :default => :test

desc 'Builds the gem'
task :build do
  sh "gem build xpay.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install ./pkg/xpay-#{Xpay::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{Xpay::Version}"
  sh "git push origin master"
  sh "git push origin v#{Xpay::Version}"
  sh "gem push xpay-#{Xpay::Version}.gem"
end
desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r xpay.rb"
end
Bundler::GemHelper.install_tasks
