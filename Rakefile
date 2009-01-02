require "rake/testtask"
require "rake/clean"
require "rake/rdoctask"
require "rake/gempackagetask"

html_dir = 'doc/html'
PROJECT = 'countloc'
PROJECT_VERSION = '0.1.0'

rubyforge_user = 'stephendoyle75'
rubyforge_project = PROJECT
rubyforge_path = "/var/www/gforge-projects/#{rubyforge_project}/"

#
# Run unit tests
#
Rake::TestTask.new('test') do |t|
  t.libs.push(File.expand_path('test'))
  t.pattern = 'test/**/ts_*.rb'
  t.warning = true
end

#
# Generate documentation
#
Rake::RDocTask.new('rdoc') do |t|
  t.rdoc_files.include(['README', 'lib/**/*.rb'])
  t.title = "#{PROJECT} API documentation"
  t.main = 'README'
  t.rdoc_dir = html_dir
end

#
# Upload documentation to Rubyforge
#
desc 'Upload documentation to RubyForge'
task 'upload-docs' => ['rdoc'] do
  sh "scp -r #{html_dir}/* " +
    "#{rubyforge_user}@rubyforge.org:#{rubyforge_path}"
end

# 
# Build a release
#
gem_spec = Gem::Specification.new do |s|
  s.name = PROJECT
  s.version = PROJECT_VERSION
  s.date = %q{2009-01-01}
  s.authors = ["Stephen Doyle"]
  s.email = %q{support@stephendoyle.net}
  s.has_rdoc = true
  s.summary = %q{Ruby line counter - countLOC}
  s.homepage = %q{http://countloc.rubyforge.org/}
  s.description = %q{LOC metrics generation script implementation in Ruby.}
  s.files = [ "README", "LICENSE", "setup.rb"] + Dir['lib/**/*.rb'] + 
    Dir['test/**/*.rb'] + Dir['examples/**/*.rb']
  s.rdoc_options << '--title' << 'CountLOC Documentation'
  s.require_paths << 'lib'
  s.rubyforge_project = PROJECT
  s.test_file = "test/ts_countloc.rb"
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

#######################################################################
# 
# Rubyforge interaction
#
#######################################################################
task "rubyforge-setup" do
  unless File.exist?(File.join(ENV["HOME"], ".rubyforge"))
    puts "rubyforge will ask you to edit its config.yml now."
    puts "Please set the 'username' and 'password' entries"
    puts "to your RubyForge username and RubyForge password!"
    $stdin.gets
    sh "rubyforge setup", :verbose => true
  end
end

task "rubyforge-login" => ["rubyforge-setup"] do 
  sh "rubyforge login", :verbose => true
end

task "publish-packages" => ["package", "rubyforge-login"] do
  # Upload packages under pkg/ to RubyForge
  # This task makes some assumptions:
  # * You have already creates a package on the "Files" tab on the
  #   RubyForge project page. See pkg_name variable below.
  # * You made entries under package_ids and group_ids for this
  #   project in rubyforge's config.yml. If not, eventually read
  #   'rubyforge --help' and then run 'rubyforge setup'.
  pkg_name = PROJECT
  cd "pkg" do
    sh("rubyforge add_release #{PROJECT} #{pkg_name} " +
      "#{PROJECT}-#{PROJECT_VERSION} #{PROJECT}-#{PROJECT_VERSION}" +
      ".gem", :verbose => true)
    sh("rubyforge add_file #{PROJECT} #{pkg_name} " +
      "#{PROJECT}-#{PROJECT_VERSION} #{PROJECT}-#{PROJECT_VERSION}" +
      ".zip")
    sh("rubyforge add_file #{PROJECT} #{pkg_name} " +
      "#{PROJECT}-#{PROJECT_VERSION} #{PROJECT}-#{PROJECT_VERSION}" +
      ".tgz")
  end
end

# The "prepare-release" task makes sure your tests run, and then generates
# files for a new release.
desc "Run tests, generate RDoc and create packages."
task "prepare-release" => ["clobber"] do
  puts "Preparing release of #{PROJECT} version #{PROJECT_VERSION}"
  Rake::Task["test"].invoke
  Rake::Task["rdoc"].invoke
  Rake::Task["package"].invoke
end

# The "publish" task is the overarching task for the whole project. It builds
# a release and then publishes it to RubyForge.
desc "Publish new release of #{PROJECT}"
task "publish" => ["prepare-release"] do
  puts "Uploading documentation ..."
  Rake::Task["upload-docs"].invoke
  puts "Checking for rubyforge command ..."
  `rubyforge --help`
  if $? == 0
    puts "Uploading packages..."
    Rake::Task["publish-packages"].invoke
    puts "Release done!"
  else
    puts "Can't invoke rubyforg command."
    puts "Either install rubyforge with 'gem install rubyforge'"
    puts "and retry or upload the package files manually!"
  end
end