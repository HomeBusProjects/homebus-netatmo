#!/usr/bin/env ruby

require './options'
require './app'

netatmo_app_options = NetatmoHomebusAppOptions.new

netatmo = NetatmoHomebusApp.new netatmo_app_options.options
#netatmo.setup!
#netatmo.work!
netatmo.run!
