# models/discount.rb
# Handles discount operations and database interactions.
class Discount
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Gets all discounts.
  #
  # @return [Array<Hash>] Array of all discount hashes
  def self.index
    db.execute('SELECT * FROM discount')
  end

  # Finds a discount by its ID.
  #
  # @param id [Integer] Discount ID
  # @return [Hash, nil] The discount hash or nil if not found
  def self.index_with_id(id)
    db.execute('SELECT * FROM discount WHERE id = ?', id).first
  end

  # Creates a new discount.
  #
  # @param name [String] Discount name
  # @param description [String] Discount description
  # @param discount_percent [Float] Discount percentage
  # @param start_date [String] Start date in ISO8601 format
  # @param end_date [String] End date in ISO8601 format
  # @return [void]
  def self.insert_new(name, description, discount_percent, start_date, end_date)
      db.execute('INSERT INTO discount (name, description, discount_percent, start_date, end_date, created_at) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)',
      [name, description, discount_percent, start_date, end_date])
  end

  # Deletes a discount.
  #
  # @param id [Integer] Discount ID to delete
  # @return [void]
  def self.delete(id)
    db.execute("PRAGMA foreign_keys = ON;")
    db.execute('DELETE FROM discount WHERE id = ?', id)
  end

  # Gets the ID of the last inserted discount.
  #
  # @return [Integer] Last inserted row ID
  def self.last_insert_id
    db.last_insert_row_id
  end
end