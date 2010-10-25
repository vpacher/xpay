# encoding: UTF-8
require File.expand_path('../lib/xpay/version', __FILE__)

Gem::Specification.new do |s|
  s.name               = 'xpay'
  s.homepage           = 'http://github.com/vpacher/xpay'
  s.summary            = 'Implementation of SecureTrading Xpay4 as gem'
  s.description        = 'This gem provides an abstraction layer to Xpay4. SecureTrading Xpay4 is a Java Applet that handles payments via SecureTrading and receives and sends xml documents.'
  s.require_path       = 'lib'
  s.authors            = ['Volker Pacher']
  s.email              = ['volker.pacher@gmail.com']
  s.version            = Xpay::Version
  s.extra_rdoc_files   = ["README.rdoc"]
  s.rdoc_options       = ["--line-numbers", "--main", "README.rdoc"]
  s.files              = Dir.glob("{bin,examples,lib,rails,test}/**/*") + %w[LICENSE UPGRADES README.rdoc] + `git ls-files`.split("\n")

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", ">= 2.0.0"
  s.add_development_dependency "shoulda"
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'log_buddy'
end
