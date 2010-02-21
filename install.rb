require 'fileutils'

# Display to the console the contents of the README file.
#puts IO.read(File.join(File.dirname(__FILE__), 'README'))

dir = File.dirname(__FILE__)
templates = File.join(dir, 'generators', 'xpay', 'templates')
config = File.join('config', 'xpay.yml')
xml_template = File.join('config', 'xpay.xml')

[config, xml_template].each do |path|
  FileUtils.cp File.join(templates, path), File.join(RAILS_ROOT, path) unless File.exist?(File.join(RAILS_ROOT, path))
end
