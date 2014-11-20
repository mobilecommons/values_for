Gem::Specification.new do |s|
  s.name = %q{values_for}
  s.version = "0.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mal McKay and Justin Leitgeb"]
  s.date = %q{2009-06-17}
  s.description = %q{Adds an enumerable attribute to an ActiveRecord-backed class}
  s.email = %q{justin@mobilecommons.com}

  s.files = `git ls-files`.split("\n")

  s.has_rdoc = true
  s.homepage = %q{http://github.com/mobilecommons/values_for}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Adds an enumerable attribute to an ActiveRecord-backed class}
  s.test_files = `git ls-files -- {spec}/*`.split("\n")

  s.extra_rdoc_files = [ "README.rdoc" ]

  s.rdoc_options += [
    '--title', 'Enum For',
    '--main', 'README.rdoc',
    '--line-numbers',
    '--inline-source'
   ]

  %w[ activerecord activesupport ].each do |dep|
    s.add_dependency(dep)
  end

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
  end
end
