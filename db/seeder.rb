require 'sqlite3'
require 'bcrypt'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    tables = %w[product discount users shopping_session order_details order_items payment_details cart_item]
    tables.each { |table| db.execute("DROP TABLE IF EXISTS #{table}") }
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
      image_url TEXT,
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
      user_id INTEGER DEFAULT NULL,
      total REAL NOT NULL DEFAULT 0.00,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE SET NULL
    );')    

    db.execute('CREATE TABLE cart_item (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER DEFAULT NULL,
      product_id INTEGER DEFAULT NULL,
      quantity INTEGER NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (session_id) REFERENCES shopping_session(id) ON DELETE SET NULL ON UPDATE SET NULL,
      FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE SET NULL ON UPDATE SET NULL
    )')
      
      #--Processed Data--#
    db.execute('CREATE TABLE order_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER DEFAULT NULL,
      total REAL NOT NULL,
      payment_id INTEGER NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE SET NULL,
      FOREIGN KEY (payment_id) REFERENCES payment_details(id) ON DELETE SET NULL ON UPDATE SET NULL
    );')

    db.execute('CREATE TABLE order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER DEFAULT NULL,
      product_id INTEGER DEFAULT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (order_id) REFERENCES order_details(id) ON DELETE SET NULL ON UPDATE SET NULL,
      FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE SET NULL ON UPDATE SET NULL
    )')

    db.execute('CREATE TABLE payment_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER DEFAULT NULL,
      amount INTEGER, 
      provider TEXT,
      status TEXT,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (order_id) REFERENCES order_details(id) ON DELETE SET NULL ON UPDATE SET NULL
    )') 
  end

  def self.populate_tables
    db.execute('INSERT INTO product (name, desc, SKU, category, price, discount_id, image_url, created_at, modified_at) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, NULL)', 
      ["Bass", "Ergonomic wireless mouse with 2.4GHz connectivity.", "WM-1001", "Electronics", 24.99, nil, "/img/bass.jpg"])
    
    db.execute('INSERT INTO product (name, desc, SKU, category, price, discount_id, image_url, created_at, modified_at) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, NULL)', 
      ["Crab paste", "RGB backlit mechanical keyboard with blue switches.", "MK-2002", "Electronics", 79.99, nil, "/img/crab_paste.jpg"])
    
    db.execute('INSERT INTO product (name, desc, SKU, category, price, discount_id, image_url, created_at, modified_at) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, NULL)', 
      ["Tackle Box", "Lightweight running shoes with breathable mesh.", "RS-3003", "Footwear", 59.99, nil, "/img/tackle_box.jpg"])
    
    db.execute('INSERT INTO product (name, desc, SKU, category, price, discount_id, image_url, created_at, modified_at) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, NULL)', 
      ["Fishing rod", "Ceramic coffee mug with 350ml capacity.", "CM-4004", "Home & Kitchen", 12.99, nil, "/img/fishing_rod.jpg"])
    
    db.execute('INSERT INTO product (name, desc, SKU, category, price, discount_id, image_url, created_at, modified_at) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, NULL)', 
      ["Tackle", "Portable Bluetooth speaker with deep bass.", "BS-5005", "Electronics", 39.99, nil, "/img/tackle.jpg"])
  
    password_hashed = BCrypt::Password.create("123")
    db.execute('INSERT INTO users (email, username, password, admin, created_at, modified_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, NULL)', 
      ["lotus.gyllensvaan@gmail.com", "admin", password_hashed, 1])
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