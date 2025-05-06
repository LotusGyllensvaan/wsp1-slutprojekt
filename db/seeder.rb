require 'sqlite3'
require 'bcrypt'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    tables = %w[product discount product_discount category_discount user shopping_session order_details order_item payment_details cart_item]
    tables.each { |table| db.execute("DROP TABLE IF EXISTS #{table}") }
  end

  def self.create_tables

    #--Static Data--#
 
    db.execute('CREATE TABLE product (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL,
      SKU TEXT NOT NULL UNIQUE,
      price REAL NOT NULL,
      image_url TEXT,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME
      )')

    db.execute('CREATE TABLE discount (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      discount_percent REAL NOT NULL CHECK(discount_percent BETWEEN 0 AND 100),
      start_date DATETIME NOT NULL,
      end_date DATETIME NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME
    )')
  
    db.execute('CREATE TABLE product_discount (
      product_id INTEGER NOT NULL,
      discount_id INTEGER NOT NULL,
      PRIMARY KEY (product_id, discount_id),
      FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (discount_id) REFERENCES discount(id) ON DELETE CASCADE ON UPDATE CASCADE
    )')

    db.execute('CREATE TABLE category_discount (
      category_id INTEGER NOT NULL,
      discount_id INTEGER NOT NULL,
      PRIMARY KEY (category_id, discount_id),
      FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (discount_id) REFERENCES discount(id) ON DELETE CASCADE ON UPDATE CASCADE
    )')

    db.execute('CREATE TABLE user (
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
      FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE SET NULL ON UPDATE SET NULL
    );')    

    db.execute('CREATE TABLE cart_item (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (session_id) REFERENCES shopping_session(id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (product_id) REFERENCES product(id) 
        ON DELETE CASCADE ON UPDATE CASCADE
    )')
      
      #--Processed Data--#
    db.execute('CREATE TABLE order_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER DEFAULT NULL,
      total REAL NOT NULL,
      payment_id INTEGER NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE SET NULL ON UPDATE SET NULL,
      FOREIGN KEY (payment_id) REFERENCES payment_details(id) ON DELETE SET NULL ON UPDATE SET NULL
    );')

    db.execute('CREATE TABLE order_item (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER DEFAULT NULL,
      product_id INTEGER DEFAULT NULL,
      quantity INTEGER NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME,
      FOREIGN KEY (order_id) REFERENCES order_details(id) ON DELETE SET NULL ON UPDATE SET NULL,
      FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE SET NULL ON UPDATE SET NULL
    )')

    db.execute('CREATE TABLE payment_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL, 
      provider TEXT,
      status TEXT,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      modified_at DATETIME
    )') 
  end

  def self.populate_tables

    # Insert products
    db.execute('INSERT INTO product (name, description, category, SKU, price, image_url, created_at) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)', 
      ["Bass", "Ergonomic wireless mouse with 2.4GHz connectivity.", "Electronics", "WM-1001", 24.99, "/img/bass.jpg"])
    bass_id = db.last_insert_row_id

    db.execute('INSERT INTO product (name, description, category, SKU, price, image_url, created_at) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)', 
      ["Crab paste", "RGB backlit mechanical keyboard with blue switches.", "Bait", "MK-2002", 79.99, "/img/crab_paste.jpg"])
    crab_id = db.last_insert_row_id

    db.execute('INSERT INTO product (name, description, category, SKU, price, image_url, created_at) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)', 
      ["Tackle Box", "Lightweight running shoes with breathable mesh.", "Storage", "RS-3003", 59.99, "/img/tackle_box.jpg"])

    db.execute('INSERT INTO product (name, description, category, SKU, price, image_url, created_at) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)', 
      ["Fishing rod", "Ceramic coffee mug with 350ml capacity.", "Rods","CM-4004", 12.99, "/img/fishing_rod.jpg"])

    db.execute('INSERT INTO product (name, description, category, SKU, price, image_url, created_at) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)', 
      ["Tackle", "Portable Bluetooth speaker with deep bass.", "Tackle", "BS-5005", 39.99, "/img/tackle.jpg"])

    db.execute('INSERT INTO discount (name, description, discount_percent, start_date, end_date, created_at) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)',
    ["Sommar Rabatt", "Sommaren är här, 20% rabatt", 20, "2025-05-04 21:28:10", "2025-06-04 21:28:10"])
    summer_discount_id = db.last_insert_row_id

    db.execute('INSERT INTO product_discount (product_id, discount_id) VALUES (?, ?)',
    [bass_id, summer_discount_id])

    db.execute('INSERT INTO product_discount (product_id, discount_id) VALUES (?, ?)',
    [crab_id, summer_discount_id])


  
    password_hashed = BCrypt::Password.create("123")
    db.execute('INSERT INTO user (email, username, password, admin, created_at, modified_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, NULL)', 
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