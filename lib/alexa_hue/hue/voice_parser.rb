require 'alexa_hue/hue/client'
require 'alexa_hue/hue/js_client'
require 'alexa_hue/hue/helpers'
require 'active_support/core_ext/hash'

module Hue
  class VoiceParser
    include Hue::Helpers
    include Singleton
    attr_accessor :client
    
    def initialize(options={})
      @client = options[:js] ? Hue::JsClient.new(options[:js]) : Hue::Client.new
    end
    
    def run(echo_response)
      @client.reset
      
      echo_response.slots.to_h.except(:state).each do |key, value|
        if value
          if value.to_s.split(' ').last == "light"
            key = "light"
            value = value[/(.*)\s/,1]
          elsif value.to_s.split(' ').last == "lights"
            key = "lights"
            value = value.to_s.split(' ').count == 1 ? "lights" : value[/(.*)\s/,1]
          end
          
          value = ((value.to_f/10.to_f)*255).to_i if (value.class == Fixnum) && (key.to_s != "fade")
          @client.send(key.to_sym, value)
        end
      end
      
      echo_response.slots.state == "off" ? @client.off : @client.on 
    end
  end
end