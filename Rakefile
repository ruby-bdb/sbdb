require 'rubygems'
require 'rdoc/task'
require 'rake/testtask'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sbdb"
    gem.summary = %Q{Simple Ruby Berkeley DB}
    gem.description = %Q{Simple Ruby Berkeley DB wrapper library for bdb.}
    gem.email = "Denis.Knauf@gmail.com"
    gem.homepage = "http://github.com/ruby-bdb/sbdb"
    gem.authors = ["Denis Knauf"]
    gem.files = %w[AUTHORS README.md VERSION lib/**/*.rb test/**/*.rb]
    gem.require_paths = %w[lib]
		gem.add_dependency 'bdb', '>= 0.2.6.5'
		gem.add_dependency 'ref'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test' << 'ext'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "sbdb #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
