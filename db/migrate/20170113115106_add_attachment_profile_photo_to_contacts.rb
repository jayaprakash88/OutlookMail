class AddAttachmentProfilePhotoToContacts < ActiveRecord::Migration
  def self.up
    change_table :contacts do |t|
      t.attachment :profile_photo
    end
  end

  def self.down
    remove_attachment :contacts, :profile_photo
  end
end
