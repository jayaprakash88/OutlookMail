class AddAttachmentJcropProfilePhotoToContacts < ActiveRecord::Migration
  def self.up
    change_table :contacts do |t|
      t.attachment :jcrop_profile_photo
    end
  end

  def self.down
    remove_attachment :contacts, :jcrop_profile_photo
  end
end
