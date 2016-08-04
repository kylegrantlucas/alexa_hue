require 'takeout'
require 'curb'
require 'oj'
require 'alexa_hue/hue/helpers'
require 'alexa_hue/hue/request_body'


module Hue
  class Client
    include Hue::Helpers
    attr_accessor :client, :user, :bridge_ip, :scenes, :groups, :lights, :schedule_ids, :schedule_params, :command, :_group, :body
    
    def initialize(options={}, &block)
      # JUST UPNP SUPPORT FOR NOW
      @bridge_ip = Oj.load(Curl.get("https://www.meethue.com/api/nupnp")).first["internalipaddress"] rescue nil
      @user = "1234567890"
      @groups, @lights, @scenes = {}, {}, []
      prefix = "/api/#{@user}"
      schemas = {
                  get: {
                    all_lights: "#{prefix}/groups/0",
                    group: "#{prefix}/groups/{{group}}",
                    root: "#{prefix}/"
                  },
                  put: {
                    scene: "#{prefix}/scenes/{{scene}}",
                    light: "#{prefix}/lights/{{lights}}/state",
                    group: "#{prefix}/groups/{{group}}/action",
                    all_lights: "#{prefix}/groups/0"
                  },
                  delete: {
                    schedule: "#{prefix}/schedules/{{schedule}}"
                  },
                  post: {
                    root: "#{prefix}/"
                  }
                }
      
      @client = Takeout::Client.new(uri: @bridge_ip, endpoint_prefix: prefix, schemas: schemas, headers: { "Expect" => "100-continue" })
      
      @lights_array, @schedule_ids, @schedule_params, @command, @_group, @body = [], [], [], "", "0", Hue::RequestBody.new

      authorize_user
      populate_client
      
      
      
      # TODO: Do blocks right
      instance_eval(&block) if block_given?
    end
    
    def confirm
      @client.put_all_lights(alert: 'select')
    end
    
    # Not currently used??
    
    # def hue(numeric_value)
    #   @body.reset
    #   @body.hue = numeric_value
    # end

    # def mired(numeric_value)
    #   @body.reset
    #   @body.ct = numeric_value
    # end

    def color(color_name)
      @body.reset
      @body.hue = @colors.keys.include?(color_name.to_sym) ? 
                        @colors[color_name.to_sym] :
                        @mired_colors[color_name.to_sym]
    end

    def saturation(depth)
      @body.clear_scene
      @body.sat = depth
    end

    def brightness(depth)
      @body.clear_scene
      @body.bri = depth
    end
    
    def fade(in_seconds)
      @body.transitiontime = in_seconds * 10
    end

    def light(*args)
      @lights_array = []
      @_group = ""
      @body.clear_scene
      args.each { |l| @lights_array.push @lights[l.to_s] if @lights.keys.include?(l.to_s) }
    end

    def lights(group_name)
      @lights_array = []
      @body.clear_scene
      group = @groups[group_name.to_s]
      @_group = group if !group.nil?
    end

    def scene(scene_name)
      @body.reset
      scene_details = @scenes[scene_name]
      @lights_array = scene_details["lights"]
      @_group = "0"
      @body.scene = scene_details["id"]
    end
    
    def savescene(scene_name)
      fade(2) if @body.transitiontime == nil
      light_group = @_group.empty? ? @client.get_all_lights.body["lights"] : @client.get_group(group: @_group).body["lights"]
      params = {name: scene_name.gsub!(' ','-'), lights: light_group, transitiontime: @body.transitiontime}
      response = @client.put_scene(scene: scene_name, options: params).body
      confirm if response.first.keys[0] == "success"
    end

    def toggle_lights
      @lights_array.each { |l| @client.put_light({lights: l}.merge(@body.to_hash)) }
    end

    def toggle_group
      @client.put_group({group: @_group}.merge(@body.to_hash(without_scene: true)))
    end

    def toggle_scene
      if @body.on
        @client.put_group({group: @_group}.merge(@body.to_hash(without_scene: true)))
      else
        @client.get_scenes[@body[:scene]]["lights"].each do |l|
          @client.put_light({lights: l}.merge(@body.to_hash))
        end
      end
    end
    
    def toggle_system
      toggle_lights if @lights_array.any? && @body.scene.nil?
      toggle_group if (!@_group.empty? && @body.scene.nil?)
      toggle_scene if @body.scene
    end
    
    def on
      @body.on = true
      toggle_system
    end

    def off
      @body.on = false
      toggle_system
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
        @schedule_ids.push(@client.post_schedules(@schedule_params).body)
        confirm if @schedule_ids.flatten.last.include?("success")
      end
    end
    
    def delete_schedules!
      @schedule_ids.flatten!
      @schedule_ids.each { |k| @client.delete_schedule(schedule: k.dig("success","id")) }
      @schedule_ids = []
    end

    def colorloop(start_or_stop)
      @body.effect = (start_or_stop == :start) ? "colorloop" : "none"
    end

    def alert(value)
      value = value.to_sym
      if value == :short
        @body.alert = "select"
      elsif value == :long
        @body.alert = "lselect"
      elsif value == :stop
        @body.alert = "none"
      end
    end

    def reset
      @command, @_group, @body, @schedule_params = "", "0", Hue::RequestBody.new, nil
    end
    
    private
        
    def authorize_user
      begin
        if @client.get_config.body.include?("whitelist") == false
          body = {:devicetype => "Hue_Switch", :username=>"1234567890"}
          create_user = @client.post_root(body).body
          puts "You need to press the link button on the bridge and run again" if create_user.first.include?("error")
        end
      rescue Errno::ECONNREFUSED
        puts "Cannot Reach Bridge"
      end
    end
    
    def populate_client
      @colors = {red: 65280, pink: 56100, purple: 52180, violet: 47188, blue: 46920, turquoise: 31146, green: 25500, yellow: 12750, orange: 8618}
      @mired_colors = {candle: 500, relax: 467, reading: 346, neutral: 300, concentrate: 231, energize: 136}
      @scenes = {} ; @client.get_scenes.body.each { |s| @scenes.merge!({"#{s[1]["name"].split(' ').first.downcase}" => {"id" => s[0]}.merge(s[1])}) if s[1]["owner"] != "none"}
      @groups = {} ; @client.get_groups.body.each { |k,v| @groups["#{v['name']}".downcase] = k } ; @groups["all"] = "0"
      @lights = {} ; @client.get_lights.body.each { |k,v| @lights["#{v['name']}".downcase] = k }
    end
  end
end
    