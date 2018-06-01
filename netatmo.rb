#!/usr/bin/env ruby

require 'atmo'
require 'mqtt'
require 'dotenv/load'
require 'json'
require 'pp'
require 'homebus'

Dotenv.load '.env.provision'

client = Atmo::Api.new
if client.authenticate            # Do authentication
  puts 'get station data'
  data = client.get_station_data  # Send request to GETSTATIONSDATA API
else
  puts 'nope'
end

pp client
pp data

mqtt = { host: ENV['MQTT_HOSTNAME'],
         port: ENV['MQTT_PORT'],
         username: ENV['MQTT_USERNAME'],
         password: ENV['MQTT_PASSWORD'],
       }

uuid = ENV['UUID']

pp mqtt

if mqtt[:host].nil?
  puts 'host is nil'

  station_name = data["body"]["devices"][0]["station_name"]
  devices = [ { friendly_name: "Temperature",
                friendly_location: station_name,
                update_frequency: 5*60*60,
                wo_topics: [ 'temperature' ],
                ro_topics: [],
                rw_topics: [] },
              { friendly_name: "Carbon Dioxide",
                friendly_location: station_name,
                update_frequency: 5*60*60,
                wo_topics: [ 'co2' ],
                ro_topics: [],
                rw_topics: [] },
              { friendly_name: 'Humidity',
                friendly_location: station_name,
                update_frequency: 5*60*60,
                wo_topics: [ 'humidity' ],
                ro_topics: [],
                rw_topics: [] },
              { friendly_name: 'Noise',
                friendly_location: station_name,
                update_frequency: 5*60*60,
                wo_topics: [ 'noise' ],
                ro_topics: [],
                rw_topics: [] },
              { friendly_name: 'Pressure',
                friendly_location: station_name,
                update_frequency: 5*60*60,
                wo_topics: [ 'pressure' ],
                ro_topics: [],
                rw_topics: [] } ]
                
  data["body"]["devices"][0]["modules"].each do |mod|
      devices.push({ friendly_name: 'Battery',
                     friendly_location: mod["module_name"],
                     update_frequency: 5*60*60,
                     wo_topics: [ 'battery' ],
                     ro_topics: [],
                     rw_topics: [] })
      devices.push({ friendly_name: 'RF Status',
                     friendly_location: mod["module_name"],
                     update_frequency: 5*60*60,
                     wo_topics: [ 'rf_status' ],
                     ro_topics: [],
                     rw_topics: [] })
    mod["data_type"].each do |data_type|
      devices.push({ friendly_name: data_type,
                     friendly_location: mod["module_name"],
                     update_frequency: 5*60*60,
                     wo_topics: [ data_type.downcase ],
                     ro_topics: [],
                     rw_topics: [] })
    end
  end

  pp devices

  mqtt = HomeBus.provision serial_number: data["body"]["devices"][0]["_id"],
                           manufacturer: 'NetAtmo',
                           model: 'Personal Weather Station',
                           friendly_name: 'NetAtmo Personal Weather Station',
                           friendly_location: station_name,
                           pin: '',
                           devices: devices
  unless mqtt
    abort 'MQTT provisioning failed'
  end

  pp mqtt

  uuid = mqtt[:uuid]
  mqtt.delete :uuid
end



exit


wun = Wunderground.new ENV['WUNDERGROUND_API_KEY']
results = wun.forecast_and_conditions_for ENV['WUNDERGROUND_LOCATION']

puts results["current_observation"]["temp_f"]

client = MQTT::Client.connect mqtt

payload = {
  temp_f: results["current_observation"]['temp_f'],
  humidity: results["current_observation"]['relative_humidity'],
  pressure: results["current_observation"]['pressure_mb'],
  device_uuid: uuid
}

client.publish "environmental/weather", payload.to_json

{"body"=>
  {"devices"=>
    [{"_id"=>"70:ee:50:01:21:50",
      "cipher_id"=>
       "enc:16:ji2fmottX0nuPwvhshkJt72hSBmzSl4cVWs86pmMMO+VEMSZOCnpmK3qptDvr6Oc",
      "date_setup"=>1373580085,
      "last_setup"=>1373580085,
      "type"=>"NAMain",
      "last_status_store"=>1526157954,
      "module_name"=>"Living Room",
      "firmware"=>132,
      "last_upgrade"=>1440562012,
      "wifi_status"=>50,
      "co2_calibrating"=>false,
      "station_name"=>"Villard Ave",
      "data_type"=>["Temperature", "CO2", "Humidity", "Noise", "Pressure"],
      "place"=>
       {"altitude"=>49.67997561719,
        "city"=>"Portland",
        "country"=>"US",
        "timezone"=>"America/Los_Angeles",
        "location"=>[-122.697218, 45.574818]},
      "dashboard_data"=>
       {"time_utc"=>1526157939,
        "Temperature"=>19.9,
        "CO2"=>418,
        "Humidity"=>60,
        "Noise"=>43,
        "Pressure"=>1014.7,
        "AbsolutePressure"=>1008.9,
        "min_temp"=>19.1,
        "max_temp"=>20.1,
        "date_min_temp"=>1526130656,
        "date_max_temp"=>1526140658,
        "temp_trend"=>"stable",
        "pressure_trend"=>"down"},
      "modules"=>
       [{"_id"=>"02:00:00:01:64:48",
         "type"=>"NAModule1",
         "module_name"=>"Outside",
         "data_type"=>["Temperature", "Humidity"],
         "last_setup"=>1373580069,
         "dashboard_data"=>
          {"time_utc"=>1491756827,
           "Temperature"=>8.9,
           "Humidity"=>78,
           "min_temp"=>3.1,
           "max_temp"=>8.9,
           "date_min_temp"=>1491745126,
           "date_max_temp"=>1491756827},
         "firmware"=>44,
         "last_message"=>1491756827,
         "last_seen"=>1491756827,
         "rf_status"=>120,
         "battery_vp"=>5206,
         "battery_percent"=>67},
        {"_id"=>"03:00:00:00:20:f4",
         "type"=>"NAModule4",
         "module_name"=>"Bedroom",
         "data_type"=>["Temperature", "CO2", "Humidity"],
         "last_setup"=>1377480263,
         "dashboard_data"=>
          {"time_utc"=>1526157893,
           "Temperature"=>19.3,
           "CO2"=>439,
           "Humidity"=>55,
           "min_temp"=>18.5,
           "max_temp"=>19.4,
           "date_min_temp"=>1526153997,
           "date_max_temp"=>1526111552,
           "temp_trend"=>"up"},
         "firmware"=>44,
         "last_message"=>1526157950,
         "last_seen"=>1526157944,
         "rf_status"=>65,
         "battery_vp"=>5125,
         "battery_percent"=>51},
        {"_id"=>"03:00:00:00:02:86",
         "type"=>"NAModule4",
         "module_name"=>"TV room",
         "data_type"=>["Temperature", "CO2", "Humidity"],
         "last_setup"=>1377481147,
         "dashboard_data"=>
          {"time_utc"=>1526157912,
           "Temperature"=>18.6,
           "CO2"=>440,
           "Humidity"=>56,
           "min_temp"=>18.5,
           "max_temp"=>19.2,
           "date_min_temp"=>1526136689,
           "date_max_temp"=>1526108496,
           "temp_trend"=>"stable"},
         "firmware"=>44,
         "last_message"=>1526157950,
         "last_seen"=>1526157912,
         "rf_status"=>65,
         "battery_vp"=>5131,
         "battery_percent"=>52},
        {"_id"=>"03:00:00:00:26:14",
         "type"=>"NAModule4",
         "module_name"=>"Garage",
         "data_type"=>["Temperature", "CO2", "Humidity"],
         "last_setup"=>1377481251,
         "dashboard_data"=>
          {"time_utc"=>1526157893,
           "Temperature"=>20.3,
           "CO2"=>425,
           "Humidity"=>54,
           "min_temp"=>18,
           "max_temp"=>20.3,
           "date_min_temp"=>1526141847,
           "date_max_temp"=>1526157893,
           "temp_trend"=>"up"},
         "firmware"=>44,
         "last_message"=>1526157950,
         "last_seen"=>1526157944,
         "rf_status"=>73,
         "battery_vp"=>5157,
         "battery_percent"=>53},
        {"_id"=>"05:00:00:00:0c:0e",
         "type"=>"NAModule3",
         "module_name"=>"Rain gauge",
         "data_type"=>["Rain"],
         "last_setup"=>1401034556,
         "dashboard_data"=>
          {"time_utc"=>1518770820, "Rain"=>0, "sum_rain_24"=>0},
         "firmware"=>8,
         "last_message"=>1518769948,
         "last_seen"=>1518769948,
         "rf_status"=>74,
         "battery_vp"=>4060,
         "battery_percent"=>19}]}],
   "user"=>
    {"mail"=>"x@x",
     "administrative"=>
      {"country"=>"US",
       "reg_locale"=>"en-US",
       "lang"=>"en-US",
       "unit"=>1,
       "windunit"=>1,
       "pressureunit"=>1,
       "feel_like_algo"=>1},
     "pending_user_consent"=>true}},
 "status"=>"ok",
 "time_exec"=>0.1872889995575,
 "time_server"=>1526158169}
