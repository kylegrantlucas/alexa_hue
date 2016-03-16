require 'client'
require 'net/http'
require 'uri'
require 'socket'
require 'ipaddr'
require 'timeout'
require 'chronic'
require 'chronic_duration'
require 'httparty'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'
require 'timeout'
module Hue
  class VoiceParser
    include Hue::Helpers
    attr_accessor :client
    
    def initialize(options={})
      @client = Hue::Client.new
    end
    
    def voice(string)
      @client.reset
      @client.command << string

      parse_voice(string)

      if @client.command.include?("schedule")
        state = string.match(/off|on/)[0].to_sym rescue nil
        @client.schedule(*[string, state])
      else
        string.include?(' off') ? @client.off : @client.on
      end
    end
    
    private
    
    def parse_leading(methods)
      methods.each do |l|
        capture = (@client.command.match (/\b#{l}\s\w+/)).to_s.split(' ')
        method = capture[0]
        value = capture[1]
        value = value.in_numbers if value.scan(Regexp.union( (1..10).map {|k| k.in_words} ) ).any?
        value = ((value.to_f/10.to_f)*255).to_i if (value.class == Fixnum) && (l != "fade")
        @client.send( method, value )
      end
    end

    def parse_trailing(method)
      all_keys = Regexp.union((@client.groups.keys + @client.lights.keys).flatten)
      value = @client.command.match(all_keys).to_s
      @client.send(method.first, value)
    end

    def parse_dynamic(methods)
      methods.each do |d|
        capture = (@client.command.match (/\w+ #{d}\b/)).to_s.split(' ')
        method = capture[1]
        value = capture[0].to_sym
        @client.send(method, value)
      end
    end

    def parse_scene(scene_name)
      scene_name.gsub!(' ','-') if scene_name.size > 1
      @client.scene(scene_name)
    end

    def parse_save_scene
      save_scene = @client.command.partition(/save (scene|seen) as /).last
      @client.save_scene(save_scene)
    end 
    
    def parse_voice(string)
      string.gsub!('schedule ','')
      trailing = string.split(' ') & %w[lights light]
      leading = string.split(' ') & %w[hue brightness saturation fade color]
      dynamic = string.split(' ') & %w[colorloop alert]
      scene_name = string.partition(" scene").first

      parse_scene(scene_name) if string.include?(" scene") && !string.include?("save")
      parse_leading(leading) if leading.any?
      parse_trailing(trailing) if trailing.any?
      parse_dynamic(dynamic) if dynamic.any?
      parse_save_scene if @client.command.scan(/save (scene|seen) as/).length > 0
    end
  end
end