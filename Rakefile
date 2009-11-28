require 'rubygems'
require 'spec'
require 'spec/rake/spectask'
require 'spec/interop/test'

task :default => :spec

desc "Run all specs"
Spec::Rake::SpecTask.new(:spec) do |t|
   t.spec_opts = ['--color']
   t.spec_files = FileList['spec/*.rb']
end

