#!/bin/env ruby
 
# One way of making an object start and stop moving gradually:
# make user input affect acceleration, not velocity.
 
require "rubygems"
require "rubygame"
 
 
# Include these modules so we can type "Surface" instead of
# "Rubygame::Surface", etc. Purely for convenience/readability.
 
include Rubygame
include Rubygame::Events
include Rubygame::EventActions
include Rubygame::EventTriggers
 
 
 
# A class representing the player's ship moving in "space".
class Ship
  include Sprites::Sprite
  include EventHandler::HasEventHandler
 
 
  def initialize( px, py )
    @px, @py = px, py # Current Position
    @vx, @vy = 0, 0 # Current Velocity
    @ax, @ay = 0, 0 # Current Acceleration
 
    @max_speed = 400.0 # Max speed on an axis
    @accel = 1200.0 # Max Acceleration on an axis
    @slowdown = 800.0 # Deceleration when not accelerating
 
    @keys = [] # Keys being pressed
 
 
    # The ship's appearance. A white square for demonstration.
    @image = Surface.new([20,20])
    @image.fill(:white)
    @rect = @image.make_rect
 
 
    # Create event hooks in the easiest way.
    make_magic_hooks(
 
      # Send keyboard events to #key_pressed() or #key_released().
      KeyPressed => :key_pressed,
      KeyReleased => :key_released,
 
      # Send ClockTicked events to #update()
      ClockTicked => :update
 
    )
  end
 
 
  private
 
 
  # Add it to the list of keys being pressed.
  def key_pressed( event )
    @keys += [event.key]
  end
 
 
  # Remove it from the list of keys being pressed.
  def key_released( event )
    @keys -= [event.key]
  end
 
 
  # Update the ship state. Called once per frame.
  def update( event )
    dt = event.seconds # Time since last update
 
    update_accel
    update_vel( dt )
    update_pos( dt )
  end
 
 
  # Update the acceleration based on what keys are pressed.
  def update_accel
    x, y = 0,0
 
    x -= 1 if @keys.include?( :left )
    x += 1 if @keys.include?( :right )
    y -= 1 if @keys.include?( :up ) # up is down in screen coordinates
    y += 1 if @keys.include?( :down )
 
    # Scale to the acceleration rate. This is a bit unrealistic, since
    # it doesn't consider magnitude of x and y combined (diagonal).
    x *= @accel
    y *= @accel
 
    @ax, @ay = x, y
  end
 
 
  # Update the velocity based on the acceleration and the time since
  # last update.
  def update_vel( dt )
    @vx = update_vel_axis( @vx, @ax, dt )
    @vy = update_vel_axis( @vy, @ay, dt )
  end
 
 
  # Calculate the velocity for one axis.
  # v = current velocity on that axis (e.g. @vx)
  # a = current acceleration on that axis (e.g. @ax)
  #
  # Returns what the new velocity (@vx) should be.
  #
  def update_vel_axis( v, a, dt )
 
    # Apply slowdown if not accelerating.
    if a == 0
      if v > 0
        v -= @slowdown * dt
        v = 0 if v < 0
      elsif v < 0
        v += @slowdown * dt
        v = 0 if v > 0
      end
    end
 
    # Apply acceleration
    v += a * dt
 
    # Clamp speed so it doesn't go too fast.
    v = @max_speed if v > @max_speed
    v = -@max_speed if v < -@max_speed
 
    return v
  end
 
 
  # Update the position based on the velocity and the time since last
  # update.
  def update_pos( dt )
    @px += @vx * dt
    @py += @vy * dt
 
    @rect.center = [@px, @py]
  end
 
end
 
 
 
# The Game class helps organize thing. It takes events
# from the queue and handles them, sometimes performing
# its own action (e.g. Escape key = quit), but also
# passing the events to the pandas to handle.
#
class Game
  include EventHandler::HasEventHandler
 
  def initialize()
    make_screen
    make_clock
    make_queue
    make_event_hooks
    make_ship
  end
 
 
  # The "main loop". Repeat the #step method
  # over and over and over until the user quits.
  def go
    catch(:quit) do
      loop do
        step
      end
    end
  end
 
 
  private
 
 
  # Create a new Clock to manage the game framerate
  # so it doesn't use 100% of the CPU
  def make_clock
    @clock = Clock.new()
    @clock.target_framerate = 50
    @clock.calibrate
    @clock.enable_tick_events
  end
 
 
  # Set up the event hooks to perform actions in
  # response to certain events.
  def make_event_hooks
    hooks = {
      :escape => :quit,
      :q => :quit,
      QuitRequested => :quit
    }
 
    make_magic_hooks( hooks )
  end
 
 
  # Create an EventQueue to take events from the keyboard, etc.
  # The events are taken from the queue and passed to objects
  # as part of the main loop.
  def make_queue
    # Create EventQueue with new-style events (added in Rubygame 2.4)
    @queue = EventQueue.new()
    @queue.enable_new_style_events
 
    # Don't care about mouse movement, so let's ignore it.
    @queue.ignore = [MouseMoved]
  end
 
 
  # Create the Rubygame window.
  def make_screen
    @screen = Screen.open( [640, 480] )
    @screen.title = "Square! In! Space!"
  end
 
 
  # Create the player ship in the middle of the screen
  def make_ship
    @ship = Ship.new( @screen.w/2, @screen.h/2 )
 
    # Make event hook to pass all events to @ship#handle().
    make_magic_hooks_for( @ship, { YesTrigger.new() => :handle } )
  end
 
 
  # Quit the game
  def quit
    puts "Quitting!"
    throw :quit
  end
 
 
  # Do everything needed for one frame.
  def step
    # Clear the screen.
    @screen.fill( :black )
 
    # Fetch input events, etc. from SDL, and add them to the queue.
    @queue.fetch_sdl_events
 
    # Tick the clock and add the TickEvent to the queue.
    @queue << @clock.tick
 
    # Process all the events on the queue.
    @queue.each do |event|
      handle( event )
    end
 
    # Draw the ship in its new position.
    @ship.draw( @screen )
 
    # Refresh the screen.
    @screen.update()
  end
 
end
 
 
# Start the main game loop. It will repeat forever
# until the user quits the game!
Game.new.go
 
 
# Make sure everything is cleaned up properly.
Rubygame.quit()