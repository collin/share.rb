$LOAD_PATH.push File.expand_path("./spec")

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end
