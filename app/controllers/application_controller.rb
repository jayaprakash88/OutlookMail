class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  ### For reference https://dev.outlook.com/restapi/tutorial/ruby
  
  protect_from_forgery with: :exception
  include AuthHelper
  def home
    # Display the login link.
    login_url = get_login_url
    render html: "<a href='#{login_url}'>Log in and view my email</a>".html_safe
    #render html: "<a href='#{contacts_new_path}'>Create New Contact</a>".html_safe
  end
end
