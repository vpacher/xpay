# encoding: UTF-8
require File.expand_path('../lib/xpay/version', __FILE__)

Gem::Specification.new do |s|
  s.name               = 'xpay'
  s.homepage           = 'http://github.com/vpacher/xpay'
  s.summary            = 'Implementation of SecureTrading Xpay4 as gem'
  s.require_path       = 'lib'
  s.authors            = ['Volker Pacher']
  s.email              = ['volker.pacher@gmail.com']
  s.version            = Xpay::Version
  s.platform           = Gem::Platform::RUBY
  s.files              = Dir.glob("{bin,examples,lib,rails,test}/**/*") + %w[LICENSE UPGRADES README.rdoc] + `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", ">= 2.0.0"
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'log_buddy'
end
