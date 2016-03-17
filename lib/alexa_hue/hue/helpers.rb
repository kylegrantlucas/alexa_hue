require 'chronic'
require 'chronic_duration'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'

module Hue
  module Helpers
    def numbers_to_times(numbers)
      numbers.map!(&:in_numbers)
      numbers.map!(&:to_s)
      numbers.push("0") if numbers[1] == nil
      numbers = numbers.shift + ':' + (numbers[0].to_i + numbers[1].to_i).to_s
      numbers.gsub!(':', ':0') if numbers.split(":")[1].length < 2
      numbers
    end

    def parse_time(string)
      string.sub!(" noon", " twelve in the afternoon")
      string.sub!("midnight", "twelve in the morning")
      time_modifier = string.downcase.scan(/(evening)|(night|tonight)|(afternoon)|(pm)|(a.m.)|(am)|(p.m.)|(morning)|(today)/).flatten.compact.first
      guess = Time.now.strftime('%H').to_i >= 12 ?  "p.m." : "a.m."
      time_modifier = time_modifier.nil? ? guess : time_modifier
      day_modifier = string.scan(/(tomorrow)|(next )?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/).flatten.compact.join(' ')
      numbers_in_words = string.scan(Regexp.union((1..59).map(&:in_words)))
      set_time = numbers_to_times(numbers_in_words)
      set_time = Chronic.parse(day_modifier +  ' ' + set_time + ' ' + time_modifier)
    end

    def set_time(string)
      if string.scan(/ seconds?| minutes?| hours?| days?| weeks?/).any?
        set_time = string.partition("in").last.strip!
        set_time = Time.now + ChronicDuration.parse(string)
      elsif string.scan(/\d/).any?
        set_time = string.partition("at").last.strip!
        set_time = Chronic.parse(set_time)
      else
        set_time = string.partition("at").last.strip!
        set_time = parse_time(set_time)
      end
    end
    
    def fix_schedule_syntax(string)
      sub_time = string.match(/time \d{2}:\d{2}/)
      sub_duration = string.match(/schedule PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)

      if sub_time
        sub_time = sub_time.to_s
        string.slice!(sub_time).strip
        string << " #{sub_time}"
        string.sub!("time", "schedule at")
      end

      if sub_duration
        sub_duration = sub_duration.to_s
        string.slice!(sub_duration).strip
        sub_duration = ChronicDuration.parse(sub_duration.split(' ').last)
        string << " schedule in #{sub_duration} seconds"
      end
      string.strip if string
    end
  end
end