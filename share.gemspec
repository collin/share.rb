lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require "share/version"

Gem::Specification.new do |s|
  s.name        = "share"
  s.version     = Share::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Collin Miller"]
  s.email       = ["collintmiller@gmail.com"]
  s.homepage    = "https://github.com/collintmiller/share.rb"
  s.summary     = "port of sharejs server to Ruby ( rack/thin )"
  s.description = "OT server for rack/rails applications. Includes JSON OT algorithms ported from ShareJS"
 
  s.required_rubygems_version = ">= 1.3.6"
  s.files        = Dir.glob("{bin,lib}/**/*") #+ %w(LICENSE README.md ROADMAP.md CHANGELOG.md)
  s.require_path = 'lib'

  s.add_dependency "websocket-rack", "~> 0.4.0"
  s.add_dependency "activesupport", "~> 3.0.0"
end
