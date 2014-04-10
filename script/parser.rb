require 'rubygems'
require 'nokogiri'
require 'json/ext'

# Parse the file at the given path
# See #parse_kml_doc for return value

LatLng = Struct.new(:lat, :lng) do
  def to_json(*a)
     "new google.maps.LatLng(#{lat.round(6)},#{lng.round(6)})"
  end
end
 
def parse_kml_file(file)
  doc = File.open(file, 'r') { |io| Nokogiri::XML.parse(io) }
  parse_kml_doc(doc)
end

# Parse the given Nokogiri doc
# Returns an array of 2-element arrays containing
# the name and coordinates of the states
def parse_kml_doc(kml_doc)
  kml_doc.css("Placemark").map do |node| # CSS-type selectors
    state  = node.css("name").first.content[0..-7].strip  # get state without year
    coords = Array.new
    node.css("coordinates").each_with_index do |c, index|
      if index > 0
        c = c.content.strip.each_line.map do |line|  # parse the string
          LatLng.new(*line.split(",").reverse.map(&:to_f)) # Get coord, reverse and round it to 6 // saves space on file
        end
        coords.push(c)
      end
    end
    [ state,  coords ] # return a tuple
  end
end

# Write out a JavaScript file with the data
def write_js_file(data, file)
  json = Hash[data].to_json
  File.open(file, 'w+') do |io|
    io << "var stateBorders = "
    io << json
    io << ";"
  end
end

# Read a KML file and write a JS file
def kml_to_js(kml_file, js_file)
  data = parse_kml_file(kml_file)
  write_js_file(data, js_file)
end

# Do everything!
kml_to_js("statesborders.kml", "stateBorders.js")