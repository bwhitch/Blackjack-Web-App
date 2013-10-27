require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  def calculate_total(cards)
  	arr = cards.map{|element| element[1]}

  	total = 0
  	arr.each do |a|
  		if a == 'A'
  			total += 11
  		else 
  			total += a.to_i == 0 ? 10 : a.to_i
  		end
  	end

  	arr.select{|element| element == "A"}.count.times do
  		break if total <=21
  		total -=10 		
  	end
  	total
  end

  def card_image(card)
  	suit = case card[0]
  	  when 'H' then 'hearts'
  	  when 'D' then 'diamonds'
  	  when 'C' then 'clubs'
  	  when 'S' then 'spades'
  	end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
    	value = case card[1]
    	when 'J' then 'jack'
    	when 'Q' then 'queen'
    	when 'K' then 'king'
    	when 'A' then 'ace'
      end
    end
  "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
  	@play_again = true
  	@show_hit_stay = false
  	@success = "#{msg} <strong> #{session[:player_name]} wins!</strong>"
  end

  def loser!(msg)
  	@play_again = true
  	@show_hit_stay = false
  	@error = "#{msg} <strong> Dealer wins. </strong>"
  end

  def tie!
  	@play_again = true
  	@show_hit_stay = false
  	@success = "<strong> Tie game! </strong>"
  end
end

before do 
	@show_hit_stay = true
end

get '/' do
	if session[:player_name]
		redirect '/game'

	else
		redirect '/new_player'
	end
end

get '/new_player' do
    erb :new_player
end

post '/new_player' do
	session[:player_name] = params[:player_name]
	redirect '/game'
end

get '/game' do
	suits = ['H', 'D', 'C', 'S']
	values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
	session[:deck] = suits.product(values).shuffle!
  
    session[:dealer_cards]=[]
    session[:player_cards]=[]
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop

    if calculate_total(session[:player_cards]) == 21
    	winner!("Blackjack!")
    elsif calculate_total(session[:dealer_cards]) == 21
    	loser!("Dealer hit Blackjack.")
    	
    end	
	erb :game
end


post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  	if player_total == 21
  		winner!("Blackjack!")
  	elsif player_total > 21	
  	  loser!("Sorry, #{session[:player_name]} busted.")
  end
  erb :game
end

post '/game/player/stay' do
	@success = session[:player_name] + ' will stay.'
	@show_hit_stay = false
	redirect '/game/dealer'
	erb :game
end

get '/game/dealer' do 
	@show_hit_stay = false

	dealer_total = calculate_total(session[:dealer_cards])
    if dealer_total == 21
    	loser!("Dealer hit Blackjack.")		
    elsif dealer_total < 17
      @show_dealer_hit_button = true
    elsif dealer_total > 21
    	winner!("Dealer busted,")
    elsif dealer_total >= 17
    	redirect '/game/compare'
    end

    erb :game
end

post '/game/dealer/hit' do
	session[:dealer_cards] << session[:deck].pop
      session[:dealer_total] = calculate_total(session[:dealer_cards])
      redirect '/game/dealer'
  erb :game
end



get '/game/compare'  do
  @show_hit_stay = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if calculate_total(session[:dealer_cards]) > calculate_total(session[:player_cards])
    loser!("Dealer has #{dealer_total}.")
  elsif calculate_total(session[:dealer_cards]) < calculate_total(session[:player_cards])
    winner!("#{session[:player_name]} has #{player_total}.")
  else
    tie!
  end
  erb :game
end

get '/game_over' do
	erb :game_over
end



