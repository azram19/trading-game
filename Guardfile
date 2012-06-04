# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'livereload', :host => '127.0.0.1', :port => '35729' do
  watch(%r{dev/webroot/(css|js)/.+\.(css|js|html)})
end

# This is an example with all options that you can specify for guard-process
guard 'process', :name => 'signal watcher', :command => 'make js', :stop_signal => "KILL"  do
  watch(%r{dev/(client|common)/.+\.coffee})
end

guard 'less', :all_on_start => true, :all_after_change => true do
  watch(%r{^.+\.less$})
end
