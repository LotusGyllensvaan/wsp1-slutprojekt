# models/order_item.rb
# Handles order item operations and database interactions.
class Order_item
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Adds a new item to an order.
  #
  # @param order_id [Integer] Order ID
  # @param product_id [Integer] Product ID
  # @param quantity [Integer] Product quantity
  # @return [void]
  def self.insert_new(order_id, product_id, quantity)
    db.execute("INSERT INTO order_item (order_id, product_id, quantity, created_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)",
    [order_id, product_id, quantity])
  end

  # Gets all purchases for an order.
  #
  # @param order_id [Integer] Order ID
  # @return [Array<Hash>] Array of purchase hashes with product details
  def self.purchases(order_id)
    db.execute("SELECT product.name, product.price, order_item.created_at, order_item.quantity
      FROM order_item
      JOIN product ON product.id = order_item.product_id
      WHERE order_item.order_id = ?", order_id
    )
  end
end