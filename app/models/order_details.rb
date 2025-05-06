# models/order_details.rb
# Handles order details operations and database interactions.
class Order_details
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Finds an order by its ID.
  #
  # @param id [Integer] Order ID
  # @return [Hash, nil] The order hash or nil if not found
  def self.index_with_id(id)
    db.get_first_row('SELECT * FROM order_details WHERE id = ?', id)
  end

  # Creates a new order.
  #
  # @param user_id [Integer] User ID who placed the order
  # @param total [Float] Order total amount
  # @param payment_id [Integer] Payment details ID
  # @return [void]
  def self.insert_new(user_id, total, payment_id)
    db.execute("INSERT INTO order_details (user_id, total, payment_id, created_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)",
    [user_id, total, payment_id])
  end

  # Gets the ID of the last inserted order.
  #
  # @return [Integer] Last inserted row ID
  def self.last_insert_id
    db.last_insert_row_id
  end
end