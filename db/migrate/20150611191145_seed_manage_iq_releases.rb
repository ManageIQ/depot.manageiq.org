class SeedManageIqReleases < ActiveRecord::Migration
  def change
    execute "INSERT INTO supported_platforms (name, released_on) VALUES ('anand-1', '2014-07-14')"
    execute "INSERT INTO supported_platforms (name, released_on) VALUES ('botvinnik-1', '2015-07-11')"
  end
end
