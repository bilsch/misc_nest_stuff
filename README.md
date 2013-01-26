misc_nest_stuff
===============

Repo for my various nest projects

- humidistat.rb
  This is a script which I hacked up to control my humidifier based on nest runtime state and humidity
  My humidiy calc is actually being done off of a grid of sensors in the house ( 1 per floor ) but you could certainly just use the nest humidity. See the code for details

- nest_stats.rb
  I use this script to pull stats from the nest. Right now it just collects current temp, target temp and humidity

  If you want to see additional details about what is available traverse the arrays/hashes. There is a TON of great stuff available
