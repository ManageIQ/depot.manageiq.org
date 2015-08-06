class CreateDailyMetrics < ActiveRecord::Migration
  def change
    create_table :daily_metrics do |t|
      t.string :key, null: false
      t.integer :count, null: false, default: 0
      t.date :day, null: false

      t.timestamps
    end
    add_index :daily_metrics, [:key, :day]
  end
end
