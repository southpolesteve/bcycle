require 'geokit'
require 'bcycle'
require 'ai4r'
require 'httparty'

stations = Bcycle.kiosks.select { |kiosk| kiosk.state == 'WI' and  kiosk.city == 'Madison' }

class Bcycle::Kiosk
  def loc
    Geokit::LatLng.new(lat, lng)
  end

  def to_s
    "#{name}"
  end
end

class Tour

  attr_accessor :current_station, :remaining_stations, :route, :total_distance, :first_station, :stations

  def initialize
    @stations = Bcycle.kiosks.select { |kiosk| kiosk.state == 'WI' and  kiosk.city == 'Madison' }
    @first_station = @stations.select{ |station| station.street == "OBSERVATORY DR. @ UW HOSPITAL" }.first
    @total_distance = 0.0
    @remaining_stations = @stations - [@first_station]
    @current_station = @first_station
    @route = [@first_station]
    @complete = false
  end

  def closest_station
    @remaining_stations.sort_by{ |station| distance_to(station) }.first
  end

  def distance_to(station)
    @current_station.loc.distance_to(station.loc)
  end

  def bike_to_closest_station
    if @remaining_stations != []
      bike_to(closest_station)
    else
      bike_home
    end
  end

  def bike_home
    bike_to(first_station)
    @complete = true
  end

  def bike_to(station)
    @total_distance += distance_to(station)
    @current_station = station
    @remaining_stations.delete station
    @route.push station
  end

  def complete_ride
    while !@complete
      bike_to_closest_station
    end
    total_distance
  end
end

tour = Tour.new
tour.complete``lete_ride
puts tour.total_distance