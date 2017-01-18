class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :email
      t.string :mobile_no
      t.date :birthday
      t.string :office_no
      t.string :company_name
      t.string :company_address
      t.string :office_hour
      t.string :job_title
      t.timestamps null: false
    end
  end
end
