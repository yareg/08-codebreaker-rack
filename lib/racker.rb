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
      Rack::Response.new(view_render('layout'))
    
    when '/game'
      @template = 'game'
      Rack::Response.new(view_render('index'))
    
    when '/game/new'
      controller.new_action
      Rack::Response.new do |response|
        response.redirect("/game")
      end
    
    when '/game/save'
      controller.save_action
      Rack::Response.new do |response|
        response.redirect("/results")
      end
    
    when '/hint'
      controller.hint_action
      Rack::Response.new do |response|
        response.redirect("/game")
      end
    
    when '/results'
      @template = 'results'
      Rack::Response.new(view_render('index'))
    
    else Rack::Response.new('Not Found', 404)
    end
  end
   
  def view_render(view)
    abs_path = File.expand_path("../views/#{view}.html.erb", __FILE__)
    ERB.new(File.read(abs_path)).result(binding)
  end
end
