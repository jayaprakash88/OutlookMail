class Contact < ActiveRecord::Base
	do_not_validate_attachment_file_type :profile_photo
	 has_attached_file :profile_photo, 
	 :styles => { :medium => "300x300>", 
	 			  :thumb => "100x100>" }, 
     :url => "/contact_photos/:id/:style_:filename"

	 has_attached_file :jcrop_profile_photo, 
	 				   :size => 1.bytes..160.megabytes,
                   	   :content_type => [:image],
	 				   :processors => [:jcropper],
	 				   :url => "/contact_photos/:id/jcrop_profile_photo/:style_:filename",
                       :styles => {
                            :thumb => "172x83#",
                            :small  => "42x42>",
                            :medium => "60x60",
                            :crop_org => Proc.new { |instance| instance.resize }	
                        } 

    attr_accessor :crop_x,:jcrop_x,:jcrop_y,:jcrop_w,:jcrop_h

    def cropping?
      !jcrop_x.blank? && !jcrop_y.blank? && !jcrop_w.blank? && !jcrop_h.blank?
    end

    def reprocess_avatar
      jcrop_profile_photo.reprocess!
    end

    def resize
      temp = self.jcrop_profile_photo.queued_for_write[:original]
      geo = Paperclip::Geometry.from_file(temp)
      "#{geo.width.round}x#{geo.height.round}!"
  end 
end
