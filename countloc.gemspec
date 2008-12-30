Gem::Specification.new do |s|
  s.name = %q{countloc}
  s.version = "0.0.1"
  s.date = %q{2008-12-30}
  s.authors = ["Stephen Doyle"]
  s.has_rdoc = true
  s.summary = %q{Ruby line counter - countLOC.}
  s.homepage = %q{http://countloc.rubyforge.org/}
  s.description = %q{LOC metrics generation script implementation in Ruby.}
  s.files = [ "README.txt", "LICENSE.txt"] + Dir['lib/**/*.rb'] + 
    Dir['test/**/*.rb'] + Dir['examples/**/*.rb']
  s.rdoc_options << '--title' << 'CountLOC Documentation'
  s.require_paths << 'lib'
  s.rubyforge_project = 'countloc'
  s.test_file = "test/ts_countloc.rb"
end