guard 'livereload', :host => '127.0.0.1', :port => '35729' do
  watch(%r{dev/webroot/(css|js)/.+\.(css|js|html)})
end

guard 'process', :name => 'signal engine watcher', :command => 'make js-engine', :stop_signal => "KILL"  do
  watch(%r{dev/common/.+\.coffee})
end

guard 'process', :name => 'signal renderer watcher', :command => 'make js-renderer', :stop_signal => "KILL"  do
  watch(%r{dev/client/renderer/.+\.coffee})
end

guard 'process', :name => 'signal templates watcher', :command => 'make js-templates', :stop_signal => "KILL"  do
  watch(%r{dev/client/templates/.+\.handlebars})
end

guard 'process', :name => 'signal views watcher', :command => 'make js-views', :stop_signal => "KILL"  do
  watch(%r{dev/client/views/.+\.coffee})
end

guard 'process', :name => 'signal models watcher', :command => 'make js-models', :stop_signal => "KILL"  do
  watch(%r{dev/client/models/.+\.coffee})
end

guard 'process', :name => 'signal collections watcher', :command => 'make js-collections', :stop_signal => "KILL"  do
  watch(%r{dev/client/collections/.+\.coffee})
end

guard 'process', :name => 'signal general js watcher', :command => 'make js-general', :stop_signal => "KILL"  do
  watch(%r{dev/client/[^\/]+\.coffee})
end

guard 'less', :all_on_start => true, :all_after_change => true do
  watch(%r{^.+\.less$})
end
