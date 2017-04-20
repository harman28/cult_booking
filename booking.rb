#!/usr/bin/env ruby

require 'json'
require 'httparty'

MAX_BOOKINGS = 3

file = File.read('schedules/harshit.json');
@config = JSON.parse(file)

def fetch_bookings
  response = HTTParty.get(
    "https://api.cultfit.in/v1/bookings", 
    headers: 
    {
      "authorization" => @config['token']
    })

  @bookings = JSON.parse(response.body)['bookings']
end

def book clas
  p "Booked #{clas['id']}"
  # HTTParty.post(
  #   "https://api.cultfit.in/v1/bookings", 
  #   { 
  #     body: {
  #       "classID"          => clas['id'],
  #       "classVersion"     => "0",
  #       "couponCode"       => null,
  #       "requestInitiator" => "webApp"
  #     },
  #     headers: {
  #       "authorization" => @config['token']
  #     }
  #   })
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
  @bookings.select{|boo| boo['id'] == clas['id']}.any?
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

fetch_bookings
fetch_classes

booking_count = get_booking_count

@classes.each do |clas|
  break if booking_count >= MAX_BOOKINGS

  if is_desired? clas and not already_booked? clas
    if available? clas
      book clas
      booking_count += 1
    else
      p "#{cl}"
    end
  end
end
