require "spec"
require "spec/rake/spectask"
require 'lib/is_less_paranoid.rb'

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = %q{is_less_paranoid}
    s.summary = %q{ActiveRecord 2.3 compatible gem "allowing you to hide and restore records without actually deleting them."  Yes, like acts_as_paranoid, only with less code and less complexity. Extended version to allow associated records to still be alive.}
    s.email = %q{pascal_hurni@fastmail.fm}
    s.homepage = %q{http://github.com/phurni/is_less_paranoid/}
    s.description = ""
    s.authors = ["Pascal Hurni", "Jeffrey Chupp"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :default  => :spec