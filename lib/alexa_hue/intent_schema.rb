module Sinatra
  module Hue
    def self.intent_schema
      File.read(File.expand_path('../../../skills_config/intent_schema.txt', __FILE__))
    end
  end
end