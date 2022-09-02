require 'homebus/options'

require 'homebus-netatmo/version'

class HomebusNetatmo::Options < Homebus::Options
  def app_options(op)
  end

  def banner
    'HomeBus Netatmo publisher'
  end

  def version
    HomebusNetatmo::VERSION
  end

  def name
    'homebus-netatmo'
  end
end
