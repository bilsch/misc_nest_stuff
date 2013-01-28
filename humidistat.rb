#!/usr/bin/ruby

#
# This script will poll my local graphite server for sensor humidity readings ( including the nest )
# If the nest is heating and the humidity is below a threshold it'll toggle the relay
# Because I'm using the wiringpi library remember to translate the gpio pin to wiringpi ( wasted 20 minutes because I forgot! )
#
# The humidity is taken from various sensors I have around the house and averaged ( call me picky ). 
# I use graphite - http://graphite.wikidot.com/
# Technically you could also just grab the humidity off of the nest and it'd work as a trigger just fine
# To do this, change the logic around line 75: avg_humidity = nest.humidity 
#
# If curious, I'm using a breadboard and a relay kit from evil mad
# scientists which is really for an arduino. I'm going to get a proper
# relay for this however the package is coming via the slowest 
# shipping method possible. I think they are hand walking it from
# China!
#
# Current relay: http://www.evilmadscience.com/productsmenu/tinykitlist/544
# Eventual relay: http://www.amazon.com/gp/product/B009AQNBJW/ref=oh_details_o00_s00_i00
#  - pretty sure this will work, says it'll trigger on 3v
#

require 'httpclient'
require 'json'
require 'nest_thermostat'
require 'wiringpi'
require 'syslog'

# main control variables
debug = false
# Note, format=json is required here
stats_url='http://some.host.somewhere/render?from=-5minutes&until=-&target=servers.raspberrypi.sensor-RED.gauge-humidity.value%2C%22RED%22%2C%22red%22&target=servers.raspberrypi.sensor-GREEN.gauge-humidity.value%2C%22GREEN%22%2C%22green%22&target=servers.raspberrypi.sensor-BASEMENT.gauge-humidity.value%2C%22BASEMENT%22%2C%22blue%22&target=servers.home.nest-some_serial_number.gauge-humidity.value%2C%22Nest%22%2C%22brown%22&format=json'
humidity_ar = []
humidity_target = 32.0
relay = 4 # wiringpi gpio pin 4 == gpio 23

# class override found here: http://stackoverflow.com/questions/1341271/average-from-a-ruby-array
# ( yes, I'm that lazy )
class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean 
    sum / size
  end
end

Syslog.open( 'humidistat', Syslog::LOG_PID, Syslog::LOG_DAEMON | Syslog::LOG_DAEMON)
Syslog.log(Syslog::LOG_INFO, "Initializing")

io = WiringPi::GPIO.new

while (1)
  # Gather nest state
  nest = NestThermostat::Nest.new({email: "__enter_your_userid__", password: "__your_password__"})
  device_id = nest.device_id
  heater_state = nest.status["shared"]["#{device_id}"]["hvac_heater_state"]
  
  # Pull stats from graphite
  client = HTTPClient.new()
  stats_txt = client.get_content(stats_url)
  stats_json = JSON.parse(stats_txt)
  
  # Now we need to traverse the json response and kick all of the datapoint values in to a single array
  stats_json.each do |sensor|
    sensor["datapoints"].each do |datapoint|
      if datapoint[0].kind_of?(Float) || datapoint[0].kind_of?(Integer)
        humidity_ar.push(datapoint[0])
      end
    end
  end
  
  # now we make some logic decisions
  avg_humidity = humidity_ar.mean
  if avg_humidity <= humidity_target
    if heater_state
      Syslog.log(Syslog::LOG_INFO, "Turn on the humidifier heater_state: #{heater_state} - #{avg_humidity} below target of #{humidity_target}")
      io.write(relay, HIGH)
      sleep(30)
      io.write(relay, LOW)
    else
      if debug 
        Syslog.log(Syslog::LOG_DEBUG, "Would turn on but Heater not running heater_state: #{heater_state} - #{avg_humidity} below target of #{humidity_target}")
      end
    end
  else
    if debug 
      Syslog.log(Syslog::LOG_DEBUG, "Leave it off - #{avg_humidity} >= target of #{humidity_target}")
    end
    io.write(relay, LOW)
  end

  # Pulse the humidifier on/off in the loop so we don't waste too much water
  if debug 
    Syslog.log(Syslog::LOG_DEBUG, "loop")
  end
  sleep(30)
end
