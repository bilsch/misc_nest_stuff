#!/usr/bin/ruby

#
# Script to populate data from the nest in to collectd
#
require 'nest_thermostat'
require 'syslog'
debug = false

Syslog.open( 'nest_stats', Syslog::LOG_PID, Syslog::LOG_DAEMON | Syslog::LOG_DAEMON)

# TODO: This really should not be so difficult to make variable but it is
@nest = NestThermostat::Nest.new({email: "__enter_your_userid__", password: "__your_password__"})
@device_id = @nest.device_id

while ( 1 )
  if debug
    Syslog.log(Syslog::LOG_INFO,  "PUTVAL \"home/nest-#{@device_id}/gauge-current_temp\" interval=10 N:#{@nest.current_temperature}")
    Syslog.log(Syslog::LOG_INFO,  "PUTVAL \"home/nest-#{@device_id}/gauge-target_temp\" interval=10 N:#{@nest.temp}")
    Syslog.log(Syslog::LOG_INFO,  "PUTVAL \"home/nest-#{@device_id}/gauge-humidity\" interval=10 N:#{@nest.humidity}")
  end

  puts "PUTVAL \"home/nest-#{@device_id}/gauge-current_temp\" interval=10 N:#{@nest.current_temperature}"
  puts "PUTVAL \"home/nest-#{@device_id}/gauge-target_temp\" interval=10 N:#{@nest.temp}"
  puts "PUTVAL \"home/nest-#{@device_id}/gauge-humidity\" interval=10 N:#{@nest.humidity}"
  STDOUT.flush
  sleep 10
end
