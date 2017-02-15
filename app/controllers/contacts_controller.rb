class ContactsController < ApplicationController
  include AuthHelper
  require 'link_thumbnailer'

  def index
    @contacts = Contact.all
    object = LinkThumbnailer.generate('http://www.tamilhindu.com')
    @data = JSON.parse(object.to_json)
  end

  def new
    @contact = Contact.new
  end

  def create
    if params[:contact][:profile_photo].present? && params[:crop_x].present?
       image = Paperclip.io_adapters.for(params[:crop_x])
       image.original_filename = params[:contact][:profile_photo].original_filename
       params[:contact][:profile_photo] = image
    end
    @contact = Contact.create(contact_params)
    if @contact.present? && params[:contact][:jcrop_profile_photo].present?
     # @contact.update_attributes(:jcrop_profile_photo => params[:contact][:jcrop_profile_photo])
      @contact.reprocess_avatar if @contact.cropping?
    end
    redirect_to contacts_index_path
  end

 def gettoken
   token = get_token_from_code params[:code]
   session[:azure_token] = token.to_hash
   session[:user_email] = get_user_email token.token
   create_outlook_contact
   redirect_to contacts_index_path ###mail_index_url ##contacts_index_url
 end

 def create_outlook_contact
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
        # Get contacts from the default contacts folder
        # Sort by GivenName in ascending orderby
        # Get the first 10 results
        request.url '/api/v2.0/Me/Contacts?$orderby=GivenName asc&$top=10'
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Accept'] = "application/json"
        request.headers['X-AnchorMailbox'] = email
      end

      @contacts = JSON.parse(response.body)['value']
      prop_id = current_user.last_visited_url.split("property_id=").last.to_i rescue ""
      @contacts && @contacts.each do |contact|
        exist_contact = !contact['GivenName'].blank? ? Contact.where("lower(name)=?", contact['GivenName'].to_s.downcase) : []
        email_address = contact['EmailAddresses'][0]['Address'] rescue ""
        business_no = contact['BusinessPhones'].blank? ? "" : contact['BusinessPhones'].first
        data = {:name =>  contact['GivenName'].to_s, :email =>  email_address,
          :mobile_no=> contact['MobilePhone1'].to_s,:birthday=> contact['Birthday'],
          :office_no=> business_no,:company_name=> contact['CompanyName'],
          :job_title=> contact['JobTitle']}
        
        if (!contact['GivenName'].blank? && exist_contact.blank?)
          contact = Contact.new(data)
          contact.save
        elsif (!contact['GivenName'].blank? && !exist_contact.blank?)
          contact = exist_contact.first.update_attributes(data)
        end
      end
      
      
      flash[:notice] = @contacts ? "Contact Created." : "Contact Not Available." 
    else
      # If no token, redirect to the root url so user
      # can sign in.
      #redirect_to root_url
      flash[:notice] = "Not able get contacts" 
    end
 end

  private

  def contact_params
    params.require(:contact).permit!
  end
end
