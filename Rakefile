require "rake/testtask"
require_relative "lib/io_streams/version"

task :gem do
  system "gem build iostreams.gemspec"
end

task publish: :gem do
  system "git tag -a v#{IOStreams::VERSION} -m 'Tagging #{IOStreams::VERSION}'"
  system "git push --tags"
  system "gem push iostreams-#{IOStreams::VERSION}.gem"
  system "rm iostreams-#{IOStreams::VERSION}.gem"
end

Rake::TestTask.new(:test) do |t|
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
  t.warning = true
end

desc "Run tests with coverage analysis"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task[:test].invoke
end

desc "Open coverage report in browser (macOS)"
task :coverage_open do
  coverage_file = File.expand_path("coverage/index.html")
  if File.exist?(coverage_file)
    system "open #{coverage_file}"
  else
    puts "Coverage report not found. Run 'rake coverage' first."
  end
end

task default: :test
