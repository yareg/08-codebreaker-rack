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
      rack_response(nil, nil, 'index', nil, false)

    when '/game/new'
      rack_response(controller, 'new_action', nil, '/play', false)

    when '/play'
      rack_response(controller, 'play_action', 'game')

    when '/game/save'
      if @request.get?
        rack_response(nil, nil, 'save_results', nil, false)
      else
        rack_response(controller, 'save_action', nil, '/results', false)
      end

    when '/game/hint'
      rack_response(controller, 'hint_action', nil, '/play', false)
    
    when '/results'
      rack_response(controller,'load_action', 'load_results')
    
    else Rack::Response.new('Not Found', 404)
    end
  end
  
  private 

  def rack_response(controller = nil, action = nil, template = nil, redirect_url = nil, bind_data = true)
    controller_result = controller.public_send(action) unless controller.nil?
    bind_results controller_result if bind_data
    if redirect_url.nil? 
      @template = template
      Rack::Response.new(view_render)
    else
      Rack::Response.new do |response|
        response.redirect(redirect_url)
      end
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
