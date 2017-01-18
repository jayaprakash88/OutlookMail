class Contact < ActiveRecord::Base
	do_not_validate_attachment_file_type :profile_photo
	 has_attached_file :profile_photo, 
	 :styles => { :medium => "300x300>", 
	 			  :thumb => "100x100>" }, 
     :url => "/contact_photos/:id/:style_:filename"
    attr_accessor :crop_x
end
