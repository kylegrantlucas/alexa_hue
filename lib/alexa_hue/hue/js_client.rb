require 'alexa_hue/hue/client'

module Hue
  class JsClient < Client
    attr_accessor :client, :user, :bridge_ip, :schedule_ids, :schedule_params, :command, :_group
    
    def initialize(options={})
      @client = Takeout::Client.new(uri: options[:uri], port: options[:port])
      @lights_array, @schedule_ids, @schedule_params, @command, @_group, @body = [], [], "", "0", Hue::RequestBody.new
    
      populate_client
    end
    
    def confirm
      @client.apply_alert(:alert => 'select')
    end
    
    def save_scene(scene_name)
      fade(2) if @body.transitiontime == nil
      if @_group.empty?
        light_group = @client.get_all_lights.body["lights"]
      else
        light_group = @client.get_group(group: @_group).body["lights"]
      end
      params = {name: scene_name.gsub!(' ','-'), lights: light_group, transitiontime: @body.transitiontime}
      response = @client.put_scene(scene: scene_name, options: params).body
      confirm if response.first.keys[0] == "success"
    end
    
    def delete_schedules!
      @schedule_ids.flatten!
      @schedule_ids.each { |k| @client.delete_schedule(schedule: k.dig("success","id")) }
      @schedule_ids = []
    end
    
    def schedule(string, on_or_off = :default)
      @body.on = (on_or_off == :on)
      set_time = set_time(string)
      unless set_time < Time.now
        set_time = set_time.to_s.split(' ')[0..1].join(' ').sub(' ',"T")
        @schedule_params = {:name=>"Hue_Switch Alarm",
               :description=>"",
               :localtime=>"#{set_time}",
               :status=>"enabled",
               :autodelete=>true
              }
        if @lights_array.any?
          lights_array.each {|l| @schedule_params[:command] = {:address=>"/api/#{@user}/lights/#{l}/state", :method=>"PUT", :body=>@body} }
        else
          @schedule_params[:command] = {:address=>"/api/#{@user}/groups/#{@_group}/action", :method=>"PUT", :body=>@body}
        end
        @schedule_ids.push(@client.post_schedules(options: @schedule_params).body)
        confirm if @schedule_ids.flatten.last.include?("success")
      end
    end

    def on
      if @body.scene
        @client.get_activate_scene(scene: @body.scene)
      end
    end
    
    def off
    end
  end
end