class RenameTypeToContentTypeInContents < ActiveRecord::Migration[7.1]
  def change
    rename_column :contents, :type, :content_type
  end
end
