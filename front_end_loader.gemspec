Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=

  s.name    = 'front_end_loader'
  s.version = '0.1.0'

  s.summary     = 'A framework for load testing in ruby'
  # TODO: s.description

  s.authors  = ['Aubrey Holland']
  s.email    = 'aubreyholland@gmail.com'
  s.homepage = 'https://github.com/brewster/front_end_loader'

  s.add_dependency 'patron'

  # = MANIFEST =
  s.files = %w[
    Gemfile
    README.md
    Rakefile
    front_end_loader.gemspec
    lib/front_end_loader.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ %r{^spec/*/.+\.rb} }
end
