# models/user.rb
# Handles user operations and database interactions.
class User
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Finds a user by ID.
  #
  # @param id [Integer] User ID
  # @return [Hash, nil] User hash or nil if not found
  def self.index_with_id(id)
    db.execute('SELECT * FROM user WHERE id = ?', id).first
  end

  # Finds a user by username.
  #
  # @param username [String] Username
  # @return [Hash, nil] User hash or nil if not found
  def self.index_with_username(username)
    db.get_first_row('SELECT * FROM user WHERE username = ?', username)
  end

  # Checks if a user with given email or username exists.
  #
  # @param email [String] Email to check
  # @param username [String] Username to check
  # @return [Hash, nil] Existing user's email/username or nil if none exists
  def self.existing_user(email, username)
    db.get_first_row(
      'SELECT email, username FROM user WHERE email = ? OR username = ?',
      [email, username]
    )
  end

  # Creates a new user.
  #
  # @param email [String] User email
  # @param username [String] Username
  # @param password_hashed [String] BCrypt hashed password
  # @return [void]
  def self.insert_new(email, username, password_hashed)
    db.execute(
      'INSERT INTO user (email, username, password, admin) VALUES(?, ?, ?, ?)',
      [email, username, password_hashed, 0]
    )
  end
end