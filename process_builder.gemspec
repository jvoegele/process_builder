# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "process_builder"

Gem::Specification.new do |s|
  s.name        = "process-builder"
  s.version     = ProcessBuilder::VERSION
  s.authors     = ["Jason Voegele"]
  s.email       = ["jason@jvoegele.com"]
  s.homepage    = "https://github.com/jvoegele/process_builder"
  s.summary     = "DEPRECATED - This gem has been replaced by process_builder"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'process_builder'
  s.add_development_dependency "rspec"
end
