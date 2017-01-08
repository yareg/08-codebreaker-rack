module CodebreakerRack
  class GameController

    STATUS_WIN = 1.freeze
    STATUS_LOST = 2.freeze
    STATUS_PLAYING = 3.freeze

    STATUS_MAP = {
        1 => 'You win!',
        2 => 'Game over!',
        3 => 'Playing',
        4 => 'Waiting for the game',
    }

    def initialize(request)
      @request = request
      @manager = (@request.session[:manager].present?)? @request.session[:manager]: nil
      @current_game = @manager.send(:current_game) unless @manager.nil?
    end

    def new_action
      @manager = Codebreaker::Manager.new
      @manager.send(:init_game)
      @request.session[:manager] = @manager
      @request.session[:game] = {}
      @request.session[:game][:answers] = []
      @request.session[:game][:status] = STATUS_PLAYING
      @request.session[:game][:hint_available] = true
    end

    def play_action
      if @current_game.present?
        game_status = @request.session[:game][:status]
        if @current_game.attempt_available? && STATUS_PLAYING == game_status

          if @request.session[:game][:use_hint]
            @request.session[:game][:hint_value] = @current_game.take_hint
            @request.session[:game][:use_hint] = false
          end

          if @request.params['answer'].present? && valid_answer?(@request.params['answer'])
            answer = @request.params['answer']
            original_answer = answer.dup
            @current_game.send(:use_attempt)
            game_result = @current_game.send(:check_attempt, answer)
            game_status = STATUS_WIN if '++++' == game_result
            @request.session[:game][:answers] << {
                answer: original_answer,
                result: game_result,
            }
          end
        end

        if !@current_game.attempt_available? && STATUS_PLAYING == game_status
          game_status = STATUS_LOST
        end

        @request.session[:game][:status] = game_status if @request.session[:game][:status] != game_status

      end

      @request.session[:game][:hint_available] = false if @request.session[:game][:hint_available] && STATUS_PLAYING != game_status

      {
         game_status_text: STATUS_MAP[game_status],
         game_active: game_status == STATUS_PLAYING,
         hint_available: @request.session[:game][:hint_available],
         hint_value: @request.session[:game][:hint_value],
         secret_code: @current_game.send(:secret_code),
         attemps_amount: Codebreaker::Game::ATTEMPTS_AMOUNT,
         answers: @request.session[:game][:answers],
      }

    end

    def hint_action
      @request.session[:game][:hint_available] = false
      @request.session[:game][:use_hint] = true
    end

    def valid_answer?(answer)
      answer =~ @manager.send(:correct_answer_pattern)
    end
  end
end
