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
        request.url '/api/v2.0/Me/Events?$orderby=Start/DateTime asc&$select=Subject,Start,End&$top=20'
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
  
def authorizing_gmail_access
    client = Signet::OAuth2::Client.new({
        client_id: APP_CONFIG[:google_client_id],
        client_secret: APP_CONFIG[:google_client_secret],
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
        redirect_uri: fetching_gmail_calendar_access_token_url
      })
    session[:calendar_event_id] = params[:event_name]
    redirect_to client.authorization_uri.to_s
  end
  
  def fetching_gmail_calendar_access_token
    client = Signet::OAuth2::Client.new({
        client_id: APP_CONFIG[:google_client_id],
        client_secret: APP_CONFIG[:google_client_secret],
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        redirect_uri: fetching_gmail_calendar_access_token_url,
        code: params[:code]
      })
    
    response = client.fetch_access_token!
    
    session[:google_calendar_auth] = response
    create_gmail_calendar_event
    redirect_to root_url
    #redirect_to calendars_url
  end
  
  def calendars
    client = Signet::OAuth2::Client.new({
        client_id: APP_CONFIG[:google_client_id],
        client_secret: APP_CONFIG[:google_client_secret],
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
      })
    
    client.update!(session[:google_calendar_auth])
    
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client
    
    @calendar_list = service.list_calendar_lists
  end
  
  def events
    client = Signet::OAuth2::Client.new({
        client_id: APP_CONFIG[:google_client_id],
        client_secret: APP_CONFIG[:google_client_secret],
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
      })
    
    client.update!(session[:google_calendar_auth])
    
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client
    
    @event_list = service.list_events(params[:calendar_id])
  end
  
  def create_gmail_calendar_event
    client = Signet::OAuth2::Client.new({
        client_id: APP_CONFIG[:google_client_id],
        client_secret: APP_CONFIG[:google_client_secret],
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
      })
    
    client.update!(session[:google_calendar_auth])
    
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client
    
    date_and_time = '%Y-%m-%d %H:%M:%S %Z'
    
    event = Google::Apis::CalendarV3::Event.new({
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.now.utc.iso8601),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.now.utc.iso8601),
      summary: session[:calendar_event_id]
      #location: @event.location,
      #description: @event.description
    })
  
    #service.insert_event(params[:calendar_id], event)
  
    begin
      service.insert_event('primary', event)
    rescue Google::Apis::AuthorizationError => exception
      response = client.refresh!

      session[:google_calendar_auth] = session[:google_calendar_auth].merge(response)

      retry
    end
    session.delete(:calendar_event_id)
  end

end
