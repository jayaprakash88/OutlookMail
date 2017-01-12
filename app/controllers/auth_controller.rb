class AuthController < ApplicationController
  def gettoken
    #render text: params[:code]
   
    #  token = get_token_from_code params[:code]
  	# email = get_user_email token.token
  	# render text: "Email: #{email}, TOKEN: #{token.token}"

    #token = get_token_from_code params[:code]
    #session[:azure_token] = token.to_hash
    #session[:user_email] = get_user_email token.token
    #render text: "Access token saved in session cookie."

    token = get_token_from_code params[:code]
  	session[:azure_token] = token.to_hash
  	session[:user_email] = get_user_email token.token
  	redirect_to contacts_index_url
  end
end
