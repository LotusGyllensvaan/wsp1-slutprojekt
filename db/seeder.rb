require 'sqlite3'
require 'bcrypt'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS products')
    db.execute('DROP TABLE IF EXISTS users')
  end

  def self.create_tables
    db.execute('CREATE TABLE products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                article TEXT NOT NULL,
                value FLOAT NOT NULL,
                description TEXT NOT NULL,
                category TEXT NOT NULL)')

    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL,
                username TEXT NOT NULL,
                password TEXT NOT NULL,
                admin BOOLEAN NOT NULL)')
    
  end

  def self.populate_tables
    db.execute('INSERT INTO products (article, value, description, category) VALUES ("Fishing Rod", 100, "High quality rod used for the most damndest of fish.", "Rods")')
    db.execute('INSERT INTO products (article, value, description, category) VALUES ("Tackle Box", 200, "Watch how I tackle box", "Storage")')
    db.execute('INSERT INTO products (article, value, description, category) VALUES ("Fishing Line", 300, "Withstand a damn behemoth", "Line")')
    db.execute('INSERT INTO products (article, value, description, category) VALUES ("Grubs", 500, "German Assasinations", "Bait")')

    password_hashed = BCrypt::Password.create("123")
    db.execute('INSERT INTO users (email, username, password, admin) VALUES (?, ?, ?, ?)', ["lotus.gyllensvaan@gmail.com", "admin", password_hashed, "1"])
  end

  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

end

Seeder.seed!