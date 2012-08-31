# Dependencies
require "csv"
require 'sunlight'

# Class Definition
class EventManager
  INVALID_ZIPCODE = "00000"
  INVALID_PHONE_NUMBER = "0000000000"
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"
  
  
  def initialize(filename)
    puts "EventManager Initialized."
    filename = "event_attendees.csv"
    @file = CSV.open(filename, "rb", {:headers => true, :header_converters => :symbol})
  end
  def output_data(filename)
      output = CSV.open(filename, "w")
      @file.each do |line|
        if @file.lineno == 2
          output << line.headers
        else
          line[:homephone] = clean_number(line[:homephone])
          line[:zipcode] = clean_zipcode(line[:zipcode])
          output << line
        end
      end
    end

    def print_names
      @file.each do |line|
        # puts line.inspect
        puts line[:first_name] + " " + line[:last_name]
        # puts "#{line[2]} #{line[3]}"
      end
    end

    def clean_number(number)
      number.delete!('./\- ()')
      if number.length == 11
        if number.start_with?("1")
          number = number[1..number.length]
        else
          number = INVALID_PHONE_NUMBER
        end
      elsif number.length == 10
        number
      else
        number = INVALID_PHONE_NUMBER
      end
      return number
    end

    def print_numbers
      @file.each do |line|
        number = clean_number(line[:homephone])
        puts number
      end
    end

    def print_zipcode
      @file.each do |line|
        zipcode = clean_zipcode(line[:zipcode])
        puts zipcode
      end
    end

    def clean_zipcode(original)
        if original.nil?
          original = INVALID_ZIPCODE
        else
          while original.length < 5
            original = "0" + original
          end
        end
        original
    end
    
    def rep_lookup
        20.times do
          line = @file.readline

          representative = "unknown"
          legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))
          
          names = legislators.collect do |leg|
            first_name = leg.firstname
            first_initial = first_name[0]
            last_name = leg.lastname
            leg.title + " " + first_initial + ". " + last_name + " (#{leg.party})"
          end
          puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
        end
    end
    
    def create_form_letters
        letter = File.open("form_letter.html", "r").read
             20.times do
               line = @file.readline
               custom_letter = letter.gsub("#first_name","#{line[:first_name]}")
               custom_letter = custom_letter.gsub("#last_name","#{line[:last_name]}")
               custom_letter = custom_letter.gsub("#city","#{line[:city]}")
               custom_letter = custom_letter.gsub("#state","#{line[:state]}")
               custom_letter = custom_letter.gsub("#street","#{line[:street]}")
               custom_letter = custom_letter.gsub("#zipcode","#{line[:zipcode]}")

               filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
               output = File.new(filename, "w")
               output.write(custom_letter)
              end
    end
    def rank_times
        hours = Array.new(24){0}
        @file.each do |line|
          reg = line[:regdate]
          part = reg.split(" ")
          hora = part[1].split(":")
          hour = hora[0].to_i
          hours[hour] += 1
        end
        hours.each_with_index{|counter,hour| puts "#{hour}\t#{counter}"}
      end

    def day_stats
      days = Array.new(7){0}
            @file.each do |line|
              day_of_week = Date.strptime( line[:regdate].split[0], "%m/%d/%y").wday
              days[day_of_week] += 1
            end
            days.each_with_index{|counter,day| puts "#{day}\t#{counter}"}
    end
    
    def state_stats
        state_data = {}
        @file.each do |line|
          state = line[:state]  # Find the State
          if state_data[state].nil? # Does the state's bucket exist in state_data?
            state_data[state] = 1 # If that bucket was nil then start it with this one person
          else
            state_data[state] = state_data[state] + 1  # If the bucket exists, add one
          end
        end
        ranks = state_data.sort_by{|state, counter| -counter}.collect{|state, counter| state}
        state_data = state_data.select{|state, counter| state}.sort_by{|state, counter| state}

        state_data.each do |state, counter|
          puts "#{state}:\t#{counter}\t(#{ranks.index(state) + 1})"
        end
      end
end

# Script
manager = EventManager.new("event_attendees.csv")
manager.state_stats
#manager.output_data("event_attendees_clean.csv")