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
      init_manager
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
            if '++++' == game_result
              game_status = STATUS_WIN
              @current_game.game_win
            end
            @request.session[:game][:answers] << {
                answer: original_answer,
                result: game_result,
            }
          end
        end

        if !@current_game.attempt_available? && STATUS_PLAYING == game_status
          game_status = STATUS_LOST
          @current_game.game_lost
        end

        @request.session[:game][:status] = game_status if @request.session[:game][:status] != game_status
      end

      @request.session[:game][:hint_available] = false if @request.session[:game][:hint_available] && STATUS_PLAYING != game_status

      {
         game_status_text: STATUS_MAP[game_status],
         game_active: game_status == STATUS_PLAYING,
         hint_available: @request.session[:game][:hint_available],
         hint_value: @request.session[:game][:hint_value],
         save_game_enabled: game_status == STATUS_WIN,
         secret_code: @current_game.send(:secret_code),
         attemps_amount: Codebreaker::Game::ATTEMPTS_AMOUNT,
         answers: @request.session[:game][:answers],
      }
    end

    def hint_action
      @request.session[:game][:hint_available] = false
      @request.session[:game][:use_hint] = true
    end

    def save_action
      if @request.post?
        if ( @current_game.present? ) && ( STATUS_WIN == @request.session[:game][:status] ) &&
            ( @request.params['user_name'].present? ) && ( valid_username? @request.params['user_name'] )

          @manager.send(:load_data_manipulator).add_game(
              @request.params['user_name'],
              @current_game.game_win?,
              @current_game.attempts_used,
              !@current_game.hint_available?
          )

          Rack::Response.new do |response|
            response.redirect('/results')
          end
        end
      end
    end

    def load_action
      init_manager unless @manager.present?
      { saved_data: @manager.send(:load_data_manipulator).return_all_data }
    end

    private

    def valid_answer?(answer)
      answer =~ @manager.send(:correct_answer_pattern)
    end

    def valid_username? (username)
      username.strip.length > 2
    end

    def init_manager
      @manager = Codebreaker::Manager.new
    end
  end
end
