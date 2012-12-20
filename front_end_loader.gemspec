Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=

  s.name    = 'front_end_loader'
  s.version = '0.3.0'

  s.summary     = 'A framework for doing declarative load testing in ruby'
  s.description = <<-EOF
Front End Loader allows clients to declare load tests using a pure-Ruby DSL.
This means that it is very simple to pass data between requests or to interact
with your systems in dynamic, complex ways.
EOF
  s.authors  = ['Aubrey Holland']
  s.email    = 'aubreyholland@gmail.com'
  s.homepage = 'https://github.com/brewster/front_end_loader'

  s.add_dependency 'patron'

  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE
    README.md
    Rakefile
    front_end_loader.gemspec
    lib/front_end_loader.rb
    lib/front_end_loader/experiment.rb
    lib/front_end_loader/request.rb
    lib/front_end_loader/request_manager.rb
    lib/front_end_loader/screen.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ %r{^spec/*/.+\.rb} }
end
