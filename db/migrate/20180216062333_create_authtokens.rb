class CreateAuthtokens < ActiveRecord::Migration[5.1]
  def change
    create_table :authtokens do |t|
      t.string :token
      t.references :merchant

      t.timestamps
    end
  end
end
