# models/product_discount.rb
# Handles product-discount relationship operations.
class Product_discount
  # Gets the database connection.
  #
  # @return [SQLite3::Database] The database connection
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  # Gets active discounts for a product.
  #
  # @param product_id [Integer] Product ID
  # @return [Array<Hash>] Array of active discount hashes
  def self.active_discounts(product_id)
    db.execute("SELECT d.*
      FROM discount d
      JOIN product_discount pd ON d.id = pd.discount_id
      WHERE pd.product_id = ?
      AND datetime(d.start_date) <= datetime('now')
      AND datetime(d.end_date) >= datetime('now')", 
      product_id)
  end

  # Calculates the total discount factor for a product.
  #
  # @param product_id [Integer] Product ID
  # @return [Float] Combined discount factor (0-1)
  def self.total_discount_factor(product_id)
    prod = db.get_first_row("SELECT 
      COALESCE(EXP(SUM(LN(1 - d.discount_percent/100.0))), 1.0) AS total_discount_factor
      FROM product p
      LEFT JOIN product_discount pd ON p.id = pd.product_id
      LEFT JOIN discount d ON pd.discount_id = d.id 
        AND datetime('now') BETWEEN d.start_date AND d.end_date
      WHERE p.id = ?
      GROUP BY p.id", product_id)
    prod['total_discount_factor'].to_f
  end

  # Links products to a discount.
  #
  # @param product_ids [Array<Integer>] Array of product IDs
  # @param discount_id [Integer] Discount ID
  # @return [void]
  def self.insert_new(product_ids, discount_id)
      values = product_ids.map { |id| "(#{id}, #{discount_id})" }.join(', ')
      db.execute("INSERT INTO product_discount (product_id, discount_id) VALUES #{values};")
  end

  # Gets all products affected by a discount.
  #
  # @param discount_id [Integer] Discount ID
  # @return [Array<Hash>] Array of product hashes
  def self.affected_products(discount_id)
    db.execute("SELECT p.* FROM product p
      JOIN product_discount pd ON p.id = pd.product_id
      WHERE pd.discount_id = ?", discount_id)
    end
end