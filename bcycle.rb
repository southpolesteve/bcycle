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

cost_matrix = []
32.times{ cost_matrix << [] }

stations.each_with_index do |station, i|
  resp = HTTParty.get('http://maps.googleapis.com/maps/api/distancematrix/json', query:
    { origins: station.loc,
      destinations: stations.map(&:loc).join("|"),
      mode: 'bicycling',
      sensor: false })
  cost_matrix[i] = resp["rows"].first['elements'].map{ |row| row['duration']['value']}
  sleep(15) # So not to upset the google
end

Ai4r::GeneticAlgorithm::Chromosome.set_cost_matrix(cost_matrix)

puts "Beginning genetic search, please wait... "
search = Ai4r::GeneticAlgorithm::GeneticSearch.new(1000, 10000)
result = search.run
puts "Result time: #{-1*result.fitness}"
puts "Result tour: "
result.data.each { |c| puts " #{tour.stations[c]}"}
