require 'json'

module Hue
  class RequestBody
    attr_accessor :hue, :ct, :bri, :scene, :sat, :transitiontime, :on, :effect, :alert
    
    def initialize(options={})
      options.each {|k,v| self.send("#{k}=".to_sym, v)}
    end
    
    def reset
      @hue, @ct, @scene = nil, nil, nil
    end
    
    def clear_scene
      @scene = nil
    end
    
    def to_json(without_scene:false)
      return self.to_hash(without_scene: without_scene).to_json
    end
    
    def to_hash(without_scene:false)
      hash = {hue: @hue, ct: @ct, bri: @bri, sat: @sat, transitiontime: @transitiontime, on: @on, effect: @effect, alert: @alert}
      hash.merge!(scene: @scene) if without_scene
      return hash
    end
  end
end