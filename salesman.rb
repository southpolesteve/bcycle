require 'geokit'
require 'pry'
require 'bcycle'

stations = Bcycle.kiosks.select { |kiosk| kiosk.state == 'WI' and  kiosk.city == 'Madison' and kiosk.active? }
start = stations.select{ |station| station.street == "OBSERVATORY DR. @ UW HOSPITAL" }.first
stations = [start] + (stations - [start])
stations = stations + [start]


class Bcycle::Kiosk
  def loc
    Geokit::LatLng.new(lat, lng)
  end

  def to_s
    "#{name}"
  end
end

class Salesman

  def initialize(nodes, opts ={})
    @nodes = nodes
    @start = opts[:start] || nil
    @end = opts[:end] || nil
    @population_count = opts[:population] || 10
    @generation_count = opts[:generations] || 100
    @generation = 0
  end

  def run
    generate_initial_population
    @generation_count.times do
      breed
    end
    return best_route
  end

  def generate_initial_population
    @population = []
    @population_count.times{ @population << Route.new(@nodes.shuffle) }
  end

  def breed
    selection
    reproduction
    elimination
  end

  def reproduction
    @offsprings = []
    0.upto(@selected.length/2-1) do |i|
      @offsprings << Route.reproduce(@selected[2*i], @selected[2*i+1])
    end
    mutate_population
  end

  def elimination
    @population.pop(@offsprings.size)
    @population.concat(@offsprings)
  end

  def mutate_population
    @population.map(&:mutate)
  end

  def best_route
    @population.sort_by{ |route| route.total_distance }.first
  end

  def worst_route
    @population.sort_by{ |route| route.total_distance }.last
  end

  def best_distance
    best_route.total_distance
  end

  def worst_distance
    worst_route.total_distance
  end

  def selection
    @selected = []
    acum_distance = 0
    if best_distance-worst_distance > 0
      @population.each do |route|
        route.normalized_distance = (route.total_distance - worst_distance)/(best_distance-worst_distance)
        acum_distance += route.normalized_distance
      end
    else
      @population.each { |route| route.normalized_distance = 1}
    end
    ((2*@population.size)/3).times do
      @selected << select_route(acum_distance)
    end
  end

  def sort_population
    @population.sort! { |a, b| b.total_distance <=> a.total_distance }
  end

  def select_route(distance)
    target = distance * rand
    local_acum = 0
    @population.each do |route|
      local_acum += route.normalized_distance
      return route if local_acum >= target
    end
  end

  class Route

    attr_accessor :nodes, :normalized_distance

    def initialize(nodes)
      @nodes = nodes
    end

    def self.reproduce(a,b)
      node = [a.nodes.dup.first, b.nodes.dup.first].shuffle.first
      spawn = [node]
      available = a.nodes.dup
      available.delete(node)
      while available.length > 0
        if node != b.nodes.last && available.include?(b.next_node(node))
          node = b.next_node(node)
        elsif node != a.nodes.last && available.include?(a.next_node(node))
          node = a.next_node(node)
        elsif node == a.nodes.last
        else
          node = available.shuffle.first
        end
        spawn << node
        available.delete(node)
        a, b = b, a if rand < 0.4
      end
      Route.new(spawn)
    end

    def next_node(node)
      nodes[nodes.index(node)+1]
    end

    def total_distance
      total = 0
      nodes.each do |node|
        unless node == @nodes.last
          total+= node.loc.distance_to(next_node(node).loc)
        end
      end
      total
    end

    # Greedy Swap http://www.generation5.org/content/2001/tspapp.asp
    def mutate
      index = rand(@nodes.length-1)
      new_nodes = @nodes.dup
      if index != 0 && index != (@nodes.size-1)
        new_nodes[index], new_nodes[index+1] = nodes[index+1], nodes[index]
        @nodes = new_nodes if Route.new(new_nodes).total_distance < total_distance
      end
    end
  end
end

puts "Beginning genetic search, please wait... "
search = Salesman.new(stations, :population => 10, :generations => 10)
result = search.run
puts "Result distance: #{result.total_distance}"
puts "Result tour: "
result.nodes.each { |c| puts c }



