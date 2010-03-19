require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "allejest"
    gem.summary = %Q{Powiadamia e-mailem o dostępności przedmiotów na allegro}
    gem.description = %Q{Powiadamia e-mailem o dostępności przedmiotów na allegro.}
    gem.email = "maciej@inszy.org"
    gem.homepage = "http://github.com/maciej/allejest"
    gem.authors = ["Maciej Bilas"]
    gem.add_development_dependency "rspec"
	gem.rubyforge_project = %q{allejest}

    gem.add_dependency 'activesupport', '>=2.3.0'
    gem.add_dependency 'feed_me', '>=0.6.0'
    gem.add_dependency 'simply_useful', '>=0.1.6'
    gem.add_dependency 'pony', '>=0.9'
    # See http://github.com/jnicklas/feed_me/issues#issue/1 feed_me depends on nokogiri, but does not specify it
    gem.add_dependency 'nokogiri'

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec


require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "allejest #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
