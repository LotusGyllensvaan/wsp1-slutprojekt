# models/product.rb
# Handles product operations and database interactions.
class Product
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Gets all products.
  #
  # @return [Array<Hash>] Array of all product hashes
  def self.index
    db.execute('SELECT * FROM product')
  end

  # Gets all products with their discount information.
  #
  # @return [Array<Hash>] Array of product hashes with discount details
  def self.index_with_discounts
    db.execute("
      SELECT 
        p.*,
        GROUP_CONCAT(d.id) AS discount_ids,
        GROUP_CONCAT(d.name) AS discount_names,
        GROUP_CONCAT(d.discount_percent) AS discount_percents,
        COALESCE(EXP(SUM(LN(1 - d.discount_percent/100.0))), 1.0) AS total_discount_factor,
        p.price * COALESCE(EXP(SUM(LN(1 - d.discount_percent/100.0))), 1.0) AS discount_price
        FROM product p
        LEFT JOIN product_discount pd ON p.id = pd.product_id
        LEFT JOIN discount d ON pd.discount_id = d.id 
          AND datetime('now') BETWEEN d.start_date AND d.end_date
        GROUP BY p.id
    ")
  end

  # Finds a product by its ID.
  #
  # @param id [Integer] Product ID
  # @return [Hash, nil] The product hash or nil if not found
  def self.index_with_id(id)
    db.execute('SELECT * FROM product WHERE id = ?', id).first
  end

  # Deletes a product by its ID.
  #
  # @param id [Integer] Product ID to delete
  # @return [void]
  def self.delete_at_id(id)
    db.execute("PRAGMA foreign_keys = ON;")
    db.execute('DELETE FROM product WHERE id = ?', id)
  end

  # Gets the image URL for a product.
  #
  # @param id [Integer] Product ID
  # @return [String, nil] The image URL or nil if none exists
  def self.image_url(id)
    db.execute('SELECT image_url FROM product WHERE id = ?', id)
  end

  # Gets the price of a product.
  #
  # @param id [Integer] Product ID
  # @return [Float] The product price
  def self.price(id)
    product = db.get_first_row("SELECT price FROM product WHERE id = ?", id)
    product['price'].to_f
  end

  # Creates a new product.
  #
  # @param name [String] Product name
  # @param price [Float] Product price
  # @param description [String] Product description
  # @param category [String] Product category
  # @param sku [String] Product SKU
  # @param image_url [String, nil] Product image URL
  # @return [void]
  def self.insert_new(name, price, description, category, sku, image_url)
    db.execute(
      'INSERT INTO product (name, price, description, category, sku, image_url) VALUES (?, ?, ?, ?, ?, ?)',
      [name, price, description, category, sku, image_url]
    )
  end

  # Gets product IDs from their names.
  #
  # @param names [Array<String>] Array of product names
  # @return [Array<Integer>] Array of product IDs
  def self.ids_from_names(names)
    placeholders = names.map{ '?' }.join(', ')
    products = db.execute("SELECT id FROM product WHERE name COLLATE NOCASE IN (#{placeholders})", names)
    products.map { |prod| prod['id'] }
  end

  # Updates a product's information.
  #
  # @param name [String] New product name
  # @param price [Float] New price
  # @param description [String] New description
  # @param category [String] New category
  # @param sku [String] New SKU
  # @param image_url [String, nil] New image URL
  # @param id [Integer] Product ID to update
  # @return [void]
  def self.update(name, price, description, category, sku, image_url=nil, id)
    if image_url
      db.execute(
        "UPDATE product SET name = ?, price = ?, description = ?, category = ?, sku = ?, image_url = ? WHERE id = ?",
        [name, price, description, category, sku, image_url, id]
      )
    else
      db.execute(
        "UPDATE product SET name = ?, price = ?, description = ?, category = ?, sku = ? WHERE id = ?",
        [name, price, description, category, sku, id]
      )
    end
  end
end