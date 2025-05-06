# models/shopping_session.rb
# Handles shopping session operations and database interactions.
class Shopping_session
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Creates a new shopping session.
  #
  # @param user_id [Integer, nil] User ID or nil for guest
  # @return [void]
  def self.insert_new(user_id)
    db.execute("INSERT INTO shopping_session (user_id, total, created_at, modified_at) VALUES (?, ?, CURRENT_TIMESTAMP, NULL)",
      [user_id, 0.00]
    )
  end

  # Gets the total amount for a shopping session.
  #
  # @param id [Integer] Session ID
  # @return [Float] Session total amount
  def self.total(id)
    shopping_session = db.execute('SELECT total FROM shopping_session WHERE id = ?', id).first
    shopping_session['total'].to_f.round(2)
  end

  # Updates the total amount for a shopping session.
  #
  # @param id [Integer] Session ID
  # @param added_price [Float] Amount to add to total
  # @return [void]
  def self.update_total(id, added_price)
    db.execute('UPDATE shopping_session SET total = total + ? WHERE id = ?', [added_price, id])
  end

  # Deletes a shopping session.
  #
  # @param session_id [Integer] Session ID to delete
  # @return [void]
  def self.delete(session_id)
    db.execute("PRAGMA foreign_keys = ON")
    db.execute("DELETE FROM shopping_session WHERE id = ?", session_id)
  end

  # Gets the ID of the last inserted shopping session.
  #
  # @return [Integer] Last inserted row ID
  def self.last_insert_id
    db.last_insert_row_id
  end
end