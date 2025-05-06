# models/cart_item.rb
# Handles cart item operations and database interactions.
class Cart_item
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Finds a cart item by its ID.
  #
  # @param id [Integer] Cart item ID
  # @return [Hash, nil] The cart item hash or nil if not found
  def self.index_with_id(id)
    db.execute('SELECT * FROM cart_item WHERE id = ?', id).first
  end

  # Gets all items in a shopping session.
  #
  # @param session_id [Integer] Shopping session ID
  # @return [Array<Hash>] Array of product hashes in the cart
  def self.items(session_id)
    db.execute("SELECT product_id, quantity FROM cart_item WHERE session_id = ?", session_id)
  end

  # Adds a new item to the cart.
  #
  # @param session_id [Integer] Shopping session ID
  # @param product_id [Integer] Product ID to add
  # @param quantity [Integer] Quantity of the product
  # @return [void]
  def self.insert_new(session_id, product_id, quantity)
    db.execute(
      'INSERT INTO cart_item (session_id, product_id, quantity) VALUES (?, ?, ?)',
      [session_id, product_id, quantity]
    )
  end

  # Gets all products in a shopping cart with details.
  #
  # @param shopping_session_id [Integer] Shopping session ID
  # @return [Array<Hash>] Array of product hashes with details
  def self.products_in_cart(shopping_session_id)
    db.execute('
      SELECT p.id AS product_id, p.name, p.description, p.SKU, p.category, p.price, ci.quantity
      FROM cart_item ci
      JOIN product p ON ci.product_id = p.id
      WHERE ci.session_id = ?',
      [shopping_session_id]
    )
  end
end