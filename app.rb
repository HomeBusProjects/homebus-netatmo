#!/usr/bin/env ruby

require 'netatmo'
require 'dotenv/load'
require 'json'
require 'pp'
require 'homebus'

class NetatmoHomebusApp < Homebus::App
  DDC_AIR_SENSOR   = 'org.homebus.experimental.air-sensor'
  DDC_CO2_SENSOR   = 'org.homebus.experimental.co2-sensor'
  DDC_NOISE_SENSOR = 'org.homebus.experimental.noise-sensor'
  DDC_RAIN_SENSOR  = 'org.homebus.experimental.rain-sensor'
  DDC_WIND_SENSOR  = 'org.homebus.experimental.wind-sensor'
  DDC_WEATHER      = 'org.homebus.experimental.weather'
  DDC_SYSTEM       = 'org.homebus.experimental.system'
  DDC_DIAGNOSTIC   = 'org.homebus.experimental.diagnostic'
  DDC_ORIGIN       = 'org.homebus.experimental.origin'
  DDC_LICENSE      = 'org.homebus.experimental.license'
  DDC_LOCATION     = 'org.homebus.experimental.location'

  def initialize(options)
    super

    @once = false
  end

  def setup!
    @client = Netatmo::Client.new do |config|
      config.client_id = ENV['NETATMO_CLIENT_ID']
      config.client_secret = ENV['NETATMO_CLIENT_SECRET']
      config.username = ENV['NETATMO_CLIENT_USERNAME']
      config.password = ENV['NETATMO_CLIENT_PASSWORD']
    end

    data = _get_netatmo_data
    _process_data data
    _create_devices
  end

  def _get_netatmo_data
    @client.authenticate
    @client.get_station_data
  end

  def _process_data(data)
    @base_station = data.devices.first
    @outdoor_module = @base_station.modules.select { |mod| mod.code == 'NAModule1' }[0]
    @wind_gauge = @base_station.modules.select { |mod| mod.code == 'NAModule2' }[0]
    @rain_gauge = @base_station.modules.select { |mod| mod.code == 'NAModule3' }[0]
    @indoor_modules = @base_station.modules.select { |mod| mod.code == 'NAModule4' }.sort { |a, b| a.id <=> b.id }
  end

  def _create_devices
    @base_device = Homebus::Device.new name: 'Netatmo Personal Weather Station',
                                       manufacturer: 'Homebus',
                                       model: '',
                                       serial_number: @base_station.id

    @outdoor_device = Homebus::Device.new name: 'NetAtmo Outdoor module',
                                          manufacturer: 'Netatmo',
                                          model: 'Weather Station',
                                          serial_number: @outdoor_module.id

    @base_device = Homebus::Device.new name: "NetAtmo Base Station #{@base_station.station_name}",
                                       manufacturer: 'Netatmo',
                                       model: 'Weather Station',
                                       serial_number: @base_station.id

    @wind_device = Homebus::Device.new name: 'NetAtmo Anenometer',
                                        manufacturer: 'NetAtmo',
                                        model: 'Weather Station',
                                        serial_number: @wind_gauge.id
                                    
    @rain_device = Homebus::Device.new name: 'NetAtmo Rain Gauge',
                                        manufacturer: 'NetAtmo',
                                        model: 'Weather Station',
                                        serial_number: @rain_gauge.id

    @indoor_devices = []
    @indoor_modules.each do |mod|
      @indoor_devices.push Homebus::Device.new name: "NetAtmo #{mod.module_name}",
                                               manufacturer: 'NetAtmo',
                                               model: 'Weather Station',
                                               serial_number: mod.id
    end
  end

  def work!
    data = _get_netatmo_data
    _process_data data

    device = devices.select { |d| d.serial_number == @base_station.id }.first

    unless @once
      payload = {
        longitude: @base_station.place.location[0],
        latitude: @base_station.place.location[1],
        altitude: @base_station.place.altitude
      }
      @base_device.publish! DDC_LOCATION, payload

      if options[:verbose]
        puts 'location'
        pp payload
      end

      @once = true
    end


    # only in base station
    payload = { noise: @base_station.noise.value }
    device.publish! DDC_NOISE_SENSOR, payload
    if options[:verbose]
      puts 'noise'
      pp payload
    end
    


    payload = { co2: @base_station.co2.value }
    device.publish! DDC_CO2_SENSOR, payload
    if options[:verbose]
      puts 'base station co2'
      pp payload
    end


    payload = { 
      temperature: @base_station.temperature.value,
      humidity: @base_station.humidity.value,
      pressure: @base_station.pressure.value
    }
    device.publish! DDC_AIR_SENSOR, payload

    if options[:verbose]
      puts 'base station air'
      pp payload
    end


    payload = {
        temperature: @outdoor_module.temperature.value,
        humidity:  @outdoor_module.humidity.value,
        pressure: @base_station.pressure.value,
        wind: @wind_gauge.wind.wind_strength,
        rain: @rain_gauge.rain.value,
        visibility: nil,
        conditions_short: nil,
        conditions_long: nil
      }

    payload[:conditions_short] = _conditions_short(payload)
    payload[:conditions_long] = _conditions_long(payload)

    # publish weather under base station's ID
    device.publish! DDC_WEATHER, payload

    if options[:verbose]
      puts 'weather'
      pp payload
    end

    # outdoor station
    device = devices.select { |d| d.serial_number == @outdoor_module.id }.first
    payload = { 
      temperature: @outdoor_module.temperature.value,
      humidity: @outdoor_module.humidity.value,
      pressure: @base_station.pressure.value
    }
    device.publish! DDC_AIR_SENSOR, payload


    # indoor modules
    @indoor_modules.each do |mod|
      device = devices.select { |d| d.serial_number == mod.id }.first

      payload =  { co2: mod.co2.value }
      device.publish! DDC_CO2_SENSOR, payload

      if options[:verbose]
        puts "#{device.name} co2"
        pp payload
      end


      payload = { 
        temperature: mod.temperature.value,
        humidity: mod.humidity.value,
        pressure: @base_station.pressure.value
      }
      device.publish! DDC_AIR_SENSOR, payload

      if options[:verbose]
        puts "#{device.name} air"
        pp payload
      end
    end

    sleep update_interval
  end

  def update_interval
    15*60
  end


  def _conditions_temperature(temperature)
    case temperature
    when ..0
      'freezing'
    when 0..13
      'cold'
    when 13..21
      'cool'
    when  21..27
      'normal'
    when 27..33
      'warm'
    else
      'hot'
    end
  end

  def _conditions_humidity(humidity)
    case humidity
    when 0..20
      'parched'
    when  20..40
      'dry'
    when 40..75
      'normal'
    when 75..90
      'moist'
    else
      'damp'
    end
  end

  def _conditions_short(payload)
    "#{_conditions_temperature(payload[:temperature]).capitalize}, #{_conditions_humidity(payload[:humidity])}"
  end

  def _conditions_long(payload)
    "Temperature is #{_conditions_temperature(payload[:temperature]).capitalize}, air feels #{_conditions_humidity(payload[:humidity])}"
  end

  def name
    'Homebus Netatmo Personal Weather Station Publisher'
  end

  def publishes
    [ DDC_AIR_SENSOR, DDC_CO2_SENSOR, DDC_NOISE_SENSOR, DDC_RAIN_SENSOR, DDC_WIND_SENSOR, DDC_WEATHER, DDC_SYSTEM, DDC_DIAGNOSTIC, DDC_ORIGIN, DDC_LICENSE, DDC_LOCATION ]
  end

  def devices
    [ @base_device, @outdoor_device, @rain_device, @wind_device, @indoor_devices[0], @indoor_devices[1], @indoor_devices[2] ]
  end
end
