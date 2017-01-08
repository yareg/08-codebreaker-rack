require 'codebreaker'
require 'erb'
require './lib/controllers/game_controller'
 
class Racker
  def self.call(env)
    new(env).response.finish
  end
   
  attr_reader :template

  def initialize(env)
    @template = 'index'
    @request = Rack::Request.new(env)
  end
   
  def response
    controller = CodebreakerRack::GameController.new(@request)
    
    case @request.path
    when '/'
      @template = 'index'
      @hint_available = false
      Rack::Response.new(view_render)

    when '/game/new'
      controller.new_action
      Rack::Response.new do |response|
        response.redirect('/play')
      end

    when '/play'
      bind_results controller.play_action
      @template = 'game'
      Rack::Response.new(view_render)

    when '/game/save'
      controller.save_action
      Rack::Response.new do |response|
        response.redirect("/results")
      end
    
    when '/game/hint'
      controller.hint_action
      Rack::Response.new do |response|
        response.redirect('/play')
      end
    
    when '/results'
      @template = 'results'
      Rack::Response.new(view_render)
    
    else Rack::Response.new('Not Found', 404)
    end
  end

  def bind_results(data)
    data.each do |key, value|
      self.class.send(:attr_accessor, key)
      send("#{key}=", value)
    end
  end
   
  def view_render(view = 'layout')
    abs_path = File.expand_path("../views/#{view}.html.erb", __FILE__)
    ERB.new(File.read(abs_path)).result(binding)
  end
end
