# Add your own tasks in files placed in config/tasks ending in .rake,
# for example config/tasks/switchtower.rake, and they will automatically be available to Rake.

require 'rake'
require 'rake/testtask'
                         

Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :default => ['test']
