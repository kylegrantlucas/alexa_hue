module Sinatra
  module Hue
    def self.custom_slots
      File.read(File.expand_path('../../../skills_config/custom_slots.txt', __FILE__))
    end
  end
end