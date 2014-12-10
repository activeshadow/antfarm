require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'

  test_files  = Dir['test/*_test.rb']
  test_files << Dir["lib/antfarm/plugins/*/**/test/*_test.rb"]

  t.test_files = test_files.flatten
end

task :default => :test
