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
    LEVELS = {} ; [*1..10].each { |t| LEVELS[t.to_s ] = t.in_words }
    
    def control_lights
      [:brightness, :saturation].each do |attribute|
        if @echo_request.slots.send(attribute)
          LEVELS.keys.reverse_each { |level| @echo_request.slots.send(attribute).sub!(level, LEVELS[level]) } if @echo_request.slots.schedule.nil? 
        end
      end

      # TODO: ...something about this feel ugly and unexpressive
      @echo_request.slots.to_h.each do |k,v| 
        @string ||= ""
        next unless v
        if k == :scene || k == :alert
          @string << "#{v.to_s} #{k.to_s}  "
        elsif k == :lights || k == :modifier || k == :state
          @string << "#{v.to_s}  "
        elsif k == :savescene
          @string << "save scene as #{v.to_s} "
        elsif k == :flash
          @string << "start long alert "
        else
          @string << "#{k.to_s} #{v.to_s}  "
        end
      end

      # TODO: create context for these statements  
      fix_schedule_syntax(@string)        
      @string.sub!("color loop", "colorloop").strip!
      
      if @echo_request.slots.scene.nil? && @echo_request.slots.savescene.nil?
        if @echo_request.slots.lights.nil? || @echo_request.slots.lights&.scan(/light|lights/).empty?
          halt AlexaObjects::Response.new(end_session: false, spoken_response: "Please specify which light or lights you'd like to adjust. I'm ready to control the lights.").to_json
        end
      end

      # TODO: 58-68 seem to both express the same thought from alexa, could be simplified?
      if @echo_request.slots.lights
        if @echo_request.slots.lights.include?('lights')
          if !(hue_client.list_groups.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.sub(' lights','')}"))
            halt AlexaObjects::Response.new(spoken_response: "I couldn't find a group with the name #{@echo_request.slots.lights}").to_json
          end
        elsif  @echo_request.slots.lights.include?('light')
          if  !(hue_client.list_lights.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.sub(' light','')}"))
            halt AlexaObjects::Response.new(spoken_response: "I couldn't find a light with the name #{@echo_request.slots.lights}").to_json
          end
        end
      end

      #TODO : majorly create context for this
      hue_client.voice @string 

      return AlexaObjects::Response.new(spoken_response: "okay").to_json
    end

    def hue_client
      begin
        @client = Hue::Switch.new
      rescue RuntimeError
        halt AlexaObjects::Response.new(spoken_response: "Hello. Before using Hue lighting, you'll need to give me access to your Hue bridge. Please press the link button on your bridge and launch the skill again within ten seconds.").to_json
      end
    end
  end
end