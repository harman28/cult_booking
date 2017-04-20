#!/usr/bin/env ruby

require 'json'
require 'httparty'

MAX_BOOKINGS = 3

WORKOUT_MAPPING = {
  1  => "Yoga",
  2  => "MMA",
  3  => "Zumba",
  4  => "Boxing",
  5  => "S & C",
  6  => "Flywheel",
  22 => "HRX Workout",
}

def fetch_bookings
  response = HTTParty.get(
    "https://api.cultfit.in/v1/bookings",
    headers:
    {
      "authorization" => @config['token']
    })

  @bookings = JSON.parse(response.body)['bookings']

  @upcoming_bookings = @bookings.select{|boo| boo['label'] == 'Upcoming'}
end

def book clas
  response = HTTParty.post(
    "https://api.cultfit.in/v1/bookings",
    {
      body: {
        "classID"          => clas['id'],
        "classVersion"     => "0",
        "requestInitiator" => "webApp"
      },
      headers: {
        "authorization" => @config['token']
      }
    })
  log_booking clas
end

def fetch_classes
  response = HTTParty.get(
    "https://api.cultfit.in/v1/classes?center=#{@config['center']}",
    headers:
    {
      "authorization" => @config['token']
    })

  @classes = JSON.parse(response.body)['classes']
end

def get_booking_count
  @bookings.select{|boo| boo['label'] == 'Upcoming'}.count
end

def already_booked? clas
  @upcoming_bookings.select{|boo| boo['classID'] == clas['id']}.any?
end

def available? clas
  clas['cultAppAvailableSeats'] > 0
end

def get_wday clas
  Date.strptime(clas['date'], '%Y-%m-%d').strftime('%A').downcase
end

def get_time clas
  Time.strptime(clas['startTime'], '%H:%M:%S').hour
end

def is_desired? clas
  wday = get_wday clas

  matching = false

  if @config['schedule'].keys.include? wday
    desired_class = @config['schedule'][wday]

    workout_match = desired_class['workout'] == clas['workoutID']
    time_match = desired_class['time'] == get_time(clas)

    matching = workout_match && time_match
  end

  return matching
end

def log_booking clas
  workout_name = WORKOUT_MAPPING[clas['workoutID']]
  msg = "#{Time.now}: "
  msg += "Booked #{workout_name} at #{clas['startTime']} on #{clas['date']}"
  @bookingfile.puts msg
  puts msg
end

def log msg
  @logfile.puts msg
end

def preset_things file
  @name = file.split((/[\.,\/]/))[1]

  @logfile = File.open("logs/#{@name}.log", 'a')

  @bookingfile = File.open("logs/#{@name}_bookings.txt", 'a')

  @config = JSON.parse(File.read(file))

  fetch_bookings
  fetch_classes
end

Dir.glob("schedules/*.json") do |file|
  preset_things file

  booking_count = get_booking_count

  @classes.each do |clas|
    break if booking_count >= MAX_BOOKINGS
    if is_desired? clas
      if already_booked? clas
        log "SKIPPED: #{clas['id']} was already booked."
      elsif available? clas
        book clas
        log "SUCCESS: Booked #{clas['id']}"
        booking_count += 1
      else
        log "FAILED: #{clas['id']} wasn't available."
      end
    end
  end
end
