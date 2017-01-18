class AlterTableCharToUtf < ActiveRecord::Migration
  def change
  	ActiveRecord::Base.connection.execute("alter table contacts convert to character set utf8mb4 collate utf8mb4_unicode_ci")
  end
end
