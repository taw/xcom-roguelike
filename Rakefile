task :default => :test

desc "Run tests"
task :test do
  sh "coffee -j xcomrl.js -c src/{core_ext,unit,map,ui,xcomrl}.coffee"
  sh "coffee -j xcomrl_test.js -c src/{core_ext,unit,map}.coffee spec/*.coffee"
  sh "node-qunit-phantomjs spec.html"
end
