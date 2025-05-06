# models/payment_details.rb
# Handles payment details operations and database interactions.
class Payment_details
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Finds payment details by ID.
  #
  # @param id [Integer] Payment details ID
  # @return [Hash, nil] The payment details hash or nil if not found
  def self.index_with_id(id)
    db.get_first_row('SELECT * FROM payment_details WHERE id = ?', id)
  end

  # Creates new payment details.
  #
  # @param amount [Float] Payment amount
  # @param provider [String] Payment provider
  # @param status [String] Payment status
  # @return [void]
  def self.insert_new(amount, provider, status)
    db.execute("INSERT INTO payment_details (amount, provider, status, created_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)",
    [amount, provider, status])
  end
  
  # Gets the ID of the last inserted payment.
  #
  # @return [Integer] Last inserted row ID
  def self.last_insert_id
    db.last_insert_row_id
  end
end