require 'alexa_hue/hue/client'
module Hue
  def self.custom_slots
    client = Hue::Client.new
    slots = "LIGHTS"
    client.instance_variable_get(("@lights").intern).keys.each {|x| slots << "\n#{x}"}
    client.instance_variable_get(("@groups").intern).keys.each {|x| slots << "\n#{x}"}
    slots << "\n\nSCENE"
    client.instance_variable_get(("@scenes").intern).keys.each {|x| slots << "\n#{x}"}
    slots << "\n"
    slots << File.read(File.expand_path('../../../skills_config/custom_slots.txt', __FILE__))
    slots
  end
end
