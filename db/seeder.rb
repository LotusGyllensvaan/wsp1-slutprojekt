require 'sqlite3'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS equipment')
  end

  def self.create_tables
    db.execute('CREATE TABLE equipment (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                article TEXT NOT NULL,
                description TEXT NOT NULL,
                category TEXT NOT NULL)')
  end

  def self.populate_tables
    
    db.execute('INSERT INTO equipment (article, description, category) VALUES ("Fishing Rod", "High quality rod used for the most damndest of fish.", "Rods")')
    db.execute('INSERT INTO equipment (article, description, category) VALUES ("Tackle Box", "Watch how I tackle box", "Storage")')
    db.execute('INSERT INTO equipment (article, description, category) VALUES ("Fishing Line", "Withstand a damn behemoth", "Line")')
    db.execute('INSERT INTO equipment (article, description, category) VALUES ("Grubs", "German Assasinations", "Bait")')
  end

  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/equipment.sqlite')
    @db.results_as_hash = true
    @db
  end

end

Seeder.seed!