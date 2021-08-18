require 'daemons'

Daemons.run('app/workers/ping_worker.rb', {
  :dir_mode => :normal,
  :dir => Dir.getwd,
  :log_output => true
})


