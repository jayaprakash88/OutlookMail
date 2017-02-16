####### Reference

###http://burnignorance.com/ruby-development-tips/creating-an-event-on-google-calendar-using-ruby-on-rails/


####https://wiki.geant.org/display/~federated-user-4/Google+Calendar+integration+with+Ruby+on+Rails

### http://stackoverflow.com/questions/35033182/google-calendar-v3-ruby-api-insert-event 

####### Reference
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = "4/ukRJROfYY-vlgRSidMIqVm3lHOozwtxGjBSFKuVViqQ"
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

# Initialize the API
service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

calendar_id = 'primary'
#event = {'summary' => 'Summary','location' => 'Location','start' => { 'dateTime' => '2017-02-20T10:00:00.000-07:00' },'end' => { 'dateTime'=> '2017-02-20T10:25:00.000-07:00' }}

#result = service.insert_event('primary', event)
#puts "Event created: #{result.html_link}"
start_time = DateTime.strptime('13/02/2017 14:25:00', '%d/%m/%Y %H:%M:%S')
end_time = DateTime.strptime('13/02/2017 15:25:00', '%d/%m/%Y %H:%M:%S')

event = Google::Apis::CalendarV3::Event.new({
  'summary':'Calender Event',
  'location':'Chennai',
  'description':'A chance to hear more about Google\'s developer products.',
  'start':{
    'date_time':  DateTime.parse('2017-02-13T14:00:00-07:00')
    #'time_zone': 'America/Los_Angeles'
  },
  'end':{
    'date_time': DateTime.parse('2017-02-13T15:00:00-07:00'),
   # 'time_zone': 'America/Los_Angeles'
  }
})

result = service.insert_event('primary', event)
puts "Event created: #{result.html_link}"

# Fetch the next 10 events for the user
calendar_id = 'primary'
response = service.list_events(calendar_id,
                               max_results: 10,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

puts "Upcoming events:"
puts "No upcoming events found" if response.items.empty?
response.items.each do |event|
  #start = event.start.date || event.start.date_time
  #puts "- #{event.summary} (#{start})"
end

