class CalendarController < ApplicationController
  include AuthHelper

  def index
     token = get_access_token
     email = session[:user_email]
    if token
      # If a token is present in the session, get messages from the inbox
      conn = Faraday.new(:url => 'https://outlook.office.com') do |faraday|
        # Outputs to the console
        faraday.response :logger
        # Uses the default Net::HTTP adapter
        faraday.adapter  Faraday.default_adapter  
      end

      response = conn.get do |request|
        # Get events from the calendar
        # Sort by Start in ascending orderby
        # Get the first 10 results
        request.url '/api/v2.0/Me/Events?$orderby=Start/DateTime asc&$select=Subject,Start,End&$top=10'
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Accept'] = "application/json"
        request.headers['X-AnchorMailbox'] = email
      end

      @events = JSON.parse(response.body)['value']
    else
      # If no token, redirect to the root url so user
      # can sign in.
      redirect_to root_url
    end
  end

 

  def authorizing_outlook_access
    client = OAuth2::Client.new(CLIENT_ID,
      CLIENT_SECRET,
      :site => "https://login.microsoftonline.com",
      :authorize_url => "/common/oauth2/v2.0/authorize",
      :token_url => "/common/oauth2/v2.0/token")
    session[:calendar_event_id] = params[:event_name]
    redirect_to client.auth_code.authorize_url(:redirect_uri => calendar_authorize_url, :scope => SCOPES.join(' '))
  end
  
  def calendar_gettoken
    #binding.pry
     token = get_token_from_code params[:code],calendar_authorize_url
     session[:azure_token] = token.to_hash
     #session[:user_email] = get_user_email token.token
     create_calendar_event
     redirect_to root_url
     # create_outlook_contact
     # redirect_to contacts_index_path ###mail_index_url ##contacts_index_url
  end
 
  def create_calendar_event
    token = get_access_token
   # email = session[:user_email]
     if token
      outlook_client = RubyOutlook::Client.new
      event = {"Subject"=>session[:calendar_event_id],
               #"Body"=> {"ContentType" =>"HTML","Content"=> @event.description},
               "Start"=>{"DateTime"=>"2017-03-18T13:00:00.0000000", "TimeZone"=>"UTC"},
               "End"=>{"DateTime"=>"2017-03-18T13:30:00.0000000", "TimeZone"=>"UTC"}
               #"Location"=> {"DisplayName"=> @event.location}
              }
       response = outlook_client.create_event token, event
       if response['ruby_outlook_error'].nil?
             flash[:notice] = "Successfully imported #{response['DisplayName']}."
          else
             flash[:notice] = "Error importing #{event['Subject']}: #{response['ruby_outlook_error']}."
       end

     else
       flash[:notice] = "Not able create event" 
     end
    session.delete(:calendar_event_id)
  end
  
end
