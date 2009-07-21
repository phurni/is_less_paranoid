# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{is_less_paranoid}
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pascal Hurni", "Jeffrey Chupp"]
  s.date = %q{2009-07-07}
  s.description = %q{}
  s.email = %q{pascal_hurni@fastmail.fm}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    "README.textile",
    "IS_PARANOID_README.textile",
    "IS_PARANOID_CHANGELOG",
    "MIT-LICENSE",
    "Rakefile",
    "VERSION.yml",
    "init.rb",
    "lib/is_less_paranoid.rb",
    "rails/init.rb",
    "reactive/init.rb",
    "spec/database.yml",
    "spec/is_paranoid_spec.rb",
    "spec/is_less_paranoid_spec.rb",
    "spec/models.rb",
    "spec/lp_models.rb",
    "spec/schema.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/phurni/is_less_paranoid/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{ActiveRecord 2.3 compatible gem "allowing you to hide and restore records without actually deleting them."  Yes, like acts_as_paranoid, only with less code and less complexity. Extended version to allow associated records to still be alive.}
  s.test_files = [
    "spec/is_paranoid_spec.rb",
    "spec/is_less_paranoid_spec.rb",
    "spec/models.rb",
    "spec/lp_models.rb",
    "spec/schema.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
