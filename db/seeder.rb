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

    #--Static Data--#
    db.execute('CREATE TABLE product (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      desc TEXT NOT NULL,
      SKU TEXT NOT NULL UNIQUE,
      category TEXT NOT NULL,
      price REAL NOT NULL,
      discount_id INTEGER DEFAULT 0,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (discount_id) REFERENCES discount (id) ON DELETE SET NULL ON UPDATE SET NULL
      )')

    db.execute('CREATE TABLE discount (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      desc TEXT NOT NULL,
      discount_percent REAL NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME
    )')
    
    db.execute('CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      admin BOOLEAN NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME
    )')

    #--Session Data--#
    
    db.execute('CREATE TABLE shopping_session (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      admin BOOLEAN NOT NULL)')    

    #--Processed Data--#
    db.execute('CREATE TABLE order_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      total FLOAT, 
      created_at TIMESTAMP,
      modified_at TIMESTAMP
    )')

    db.execute('CREATE TABLE order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      product_id,
      created_at TIMESTAMP,
      modified_at TIMESTAMP
    )')

    db.execute('CREATE TABLE payment_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      amount INTEGER, 
      provider TEXT,
      status TEXT,
      created_at TIMESTAMP,
      modified_at TIMESTAMP
    )')    
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