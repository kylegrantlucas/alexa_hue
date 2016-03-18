require 'json'
require 'alexa_objects'
require 'httparty'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'
require 'chronic'
require 'alexa_hue/version'
require 'sinatra/extension'
require 'numbers_in_words/duck_punch'
require 'alexa_hue/hue/voice_parser'
require 'alexa_hue/hue/helpers'
require 'chronic_duration'

module Hue
  include Hue::Helpers
  extend Sinatra::Extension

  helpers do
    def voice_parser
      Hue::VoiceParser.instance
    end
    
    def control_lights
      Thread.start do 
        [:brightness, :saturation].each { |attribute| @echo_request.slots.send("#{attribute}=", @echo_request.slots.send(attribute)&.to_i) unless @echo_request.slots.schedule }

        voice_parser.run @echo_request
      end

      if (@echo_request.slots.lights.nil? && @echo_request.slots.scene.nil? && @echo_request.slots.savescene.nil?) || (@echo_request.slots.lights && @echo_request.slots.lights.scan(/light|lights/).empty?)
        halt AlexaObjects::Response.new(end_session: false, spoken_response: "Please specify which light or lights you'd like to adjust. I'm ready to control the lights.").to_json
      end

      # if @echo_request.slots.lights
      #   if @echo_request.slots.lights.include?('lights')
      #     if !(switch.list_groups.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.sub(' lights','')}"))
      #       halt AlexaObjects::Response.new(spoken_response: "I couldn't find a group with the name #{@echo_request.slots.lights}").to_json
      #     end
      #   elsif  @echo_request.slots.lights.include?('light')
      #     if  !(switch.list_lights.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.sub(' light','')}"))
      #       halt AlexaObjects::Response.new(spoken_response: "I couldn't find a light with the name #{@echo_request.slots.lights}").to_json
      #     end
      #   end
      # end

      return AlexaObjects::Response.new(spoken_response: "okay").to_json
    end
  end
end