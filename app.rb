
# app.rb
require 'sinatra/base'
require 'securerandom'
require 'fileutils'

Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'controllers', '*.rb')].each { |file| require file }

# Mount controllers
class App < Sinatra::Base
  # Application-wide configuration block.
  configure do
    # Enables session handling.
    enable :sessions

    # Sets a secure session secret.
    set :session_secret, SecureRandom.hex(64)

    # Sets session expiration to one week.
    set :sessions, expire_after: 60 * 60 * 24 * 7

    # Escapes HTML in ERB templates by default.
    set :erb, escape_html: true
  end

  # Executes before each request.
  #
  # Escapes all string parameters to prevent XSS,
  # assigns the current user to @user,
  # and ensures a shopping session unless on specific paths.
  before do
    params.each do |key, value|
      params[key] = Rack::Utils.escape_html(value) if value.is_a?(String)
    end

    @user = user

    unless ['/login', '/user/new', '/unauthorized'].include?(request.path_info)
      ensure_shopping_session
    end
  end

  helpers do
    # Checks if the current user is authorized (admin).
    #
    # @return [Boolean] true if user is admin, false otherwise
    def authorized?
      @user && @user['admin'].to_i == 1
    end

    # Redirects to the unauthorized page if the user is not authorized.
    #
    # Sets the WWW-Authenticate header for HTTP basic authentication.
    #
    # @return [void]
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      redirect '/unauthorized'
    end

    # Retrieves the current user based on session data.
    #
    # @return [Hash, nil] the user hash or nil if not found
    def user
      User.index_with_id(session[:user_id].to_i)
    end

    # Ensures that a shopping session exists for the user.
    #
    # Creates a new shopping session and stores its ID in the session hash
    # if one doesn't already exist.
    #
    # @return [void]
    def ensure_shopping_session
      return if session[:shopping_session_id]
      user_id = session[:user_id] || nil
      Shopping_session.insert_new(user_id)

      session[:shopping_session_id] = Shopping_session.last_insert_id
    end
  end

  # Redirects root path to the product page.
  #
  # @return [Sinatra::Response] redirect to /product
  get '/' do
    redirect '/product'
  end

  # Renders the unauthorized access page.
  #
  # @return [String] HTML content of unauthorized page
  get '/unauthorized' do
    erb :unauthorized
  end

  # Displays the contents of the shopping cart.
  #
  # @return [String] Rendered cart page with products and total
  get '/cart/show' do
    @cart_products = Cart_item.products_in_cart(session[:shopping_session_id])
    @total = Shopping_session.total(session[:shopping_session_id])
    erb :"cart/show"
  end
  
  # Adds a product to the cart with specified quantity.
  #
  # @param id [Integer] Product ID to add to cart
  # @return [void] Redirects to products page
  post '/cart/:id' do |id|
    quantity = params['quantity'].to_i
  
    if quantity > 0
      cart_item_values = [session[:shopping_session_id], id, quantity]
      Cart_item.insert_new(*cart_item_values)
  
      total_discount_factor = Product_discount.total_discount_factor(id)
  
      added_price = (Product.price(id) * total_discount_factor * quantity).round(2)
      Shopping_session.update_total(session[:shopping_session_id], added_price)
    end
    redirect '/product'
  end
  
  # Processes the checkout and creates an order.
  #
  # @return [void] Redirects to order confirmation page
  post '/checkout' do
    session_id = session[:shopping_session_id]
    cart_items = Cart_item.items(session_id)
    total = Shopping_session.total(session_id)
  
    Payment_details.insert_new(total, 'credit_card', 'pending')
    payment_id = Payment_details.last_insert_id
    user_id = session[:user_id]
  
    Order_details.insert_new(user_id, total, payment_id)
    order_id = Order_details.last_insert_id
  
    cart_items.each do |item|
      product_id = item['product_id']
      quantity = item['quantity']
  
      Order_item.insert_new(order_id, product_id, quantity)
    end
  
    Shopping_session.delete(session_id)
    session[:shopping_session_id] = nil
  
    redirect "/order/confirmation/#{order_id}"
  end

  # Displays all discounts.
  #
  # @return [String] Rendered discounts index page
  get '/discount' do
    protected!
    @discounts = Discount.index
    erb :"discount/index"
  end
  
  # Creates a new discount for specified products.
  #
  # @return [void] Redirects to discounts page
  post '/discount' do
    protected!
    discounted_products = params['discounted_products'].split(', ')
    start_datetime = Time.parse(params['start_date']).utc.iso8601
    end_datetime = Time.parse(params['end_date']).utc.iso8601
  
    discount_values = [
      params['name'],
      params['description'],
      params['discount_percent'],
      start_datetime,
      end_datetime
    ]
  
    Discount.insert_new(*discount_values)
    discount_id = Discount.last_insert_id
    
    product_ids = Product.ids_from_names(discounted_products)
    Product_discount.insert_new(product_ids, discount_id)
    redirect '/discount'
  end
  
  # Deletes a discount.
  #
  # @param id [Integer] Discount ID to delete
  # @return [void] Redirects to discounts page
  post '/discount/:id/delete' do |id|
    protected!
    Discount.delete(id)
    redirect '/discount'
  end
  
  # Shows details of a specific discount.
  #
  # @param id [Integer] Discount ID to show
  # @return [String] Rendered discount details page
  get '/discount/:id' do |id|
    protected!
    @affected_products = Product_discount.affected_products(id)
    erb :"/discount/show"
  end

  # Shows order confirmation details.
  #
  # @param order_id [Integer] Order ID to display
  # @return [String] Rendered order confirmation page
  # @raise [RuntimeError] If order is not found
  get '/order/confirmation/:order_id' do |order_id|
    order = Order_details.index_with_id(order_id)
    halt 404, "Order not found" unless order
  
    payment = Payment_details.index_with_id(order['payment_id'])
    purchases = Order_item.purchases(order_id)
    erb :order_confirmation, locals: { order: order, payment: payment, purchases: purchases }
  end
  
  # Displays all products with their discounts.
  #
  # @return [String] Rendered products index page
  get '/product' do
    @user = user
    @products = Product.index_with_discounts.map do |prod|
      discounts = if prod['discount_ids']
        ids = prod['discount_ids'].split(',')
        names = prod['discount_names'].split(',')
        percents = prod['discount_percents'].split(',')
        
        ids.each_with_index.map do |id, i|
          { 'id' => id, 'name' => names[i], 'discount_percent' => percents[i] }
        end
      else
        []
      end
      
      discount_price = prod['price'].to_f * prod['total_discount_factor'].to_f
      has_discount = discounts.length > 0
      prod.merge(
        discount_price: discount_price,
        has_discount: has_discount,
        discounts: discounts,
        total_discount: (prod['total_discount_factor'].to_f)
      )
    end
  
    erb :"product/index"
  end

  # Displays form for creating new product (admin only).
  #
  # @return [String] Rendered new product form
  get '/product/new' do
    protected!
    @products = Product.index
    erb :"product/new"
  end

  # Creates a new product (admin only).
  #
  # @return [void] Redirects to new product form
  post '/product' do
    protected!
    image = params[:image]
    image_filename = nil
  
    if image && image[:filename]
      uploads_dir = File.join(settings.public_folder, 'img')
      FileUtils.mkdir_p(uploads_dir)
  
      image_filename = "#{Time.now.to_i}_#{image[:filename]}"
      image_path = File.join(uploads_dir, image_filename)
  
      File.open(image_path, 'wb') do |f|
        f.write(image[:tempfile].read)
      end
    end
  
    Product.insert_new(
      params['article'],
      params['value'],
      params['description'],
      params['category'],
      params['SKU'],
      image_filename ? "img/#{image_filename}" : nil
    )
  
    redirect('/product/new')
  end
  
  # Shows details for a specific product.
  #
  # @param id [Integer] Product ID to display
  # @return [String] Rendered product details page
  get '/product/:id' do |id|
    p @product = Product.index_with_id(id)
    @active_discounts = Product_discount.active_discounts(@product['id'])
    erb :"product/show"
  end

  # Deletes a product (admin only).
  #
  # @param id [Integer] Product ID to delete
  # @return [void] Redirects to new product form
  post '/product/:id/delete' do |id|
    protected!
    Product.delete_at_id(id)
    redirect '/product/new'
  end

  # Displays form for editing a product (admin only).
  #
  # @param id [Integer] Product ID to edit
  # @return [String] Rendered product edit form
  get '/product/:id/edit' do |id|
    protected!
    @product = Product.index_with_id(id)
    erb :"product/edit"
  end
  
  # Updates a product (admin only).
  #
  # @param id [Integer] Product ID to update
  # @return [void] Redirects to new product form
  post '/product/:id/update' do |id|
    protected!
    name = params['name']
    desc = params['desc']
    price = params['price']
    category = params['category']
    sku = params['sku']
  
    image = params['image']
    image_url = Product.image_url(id)
    image_url = nil
  
    if image && image[:filename] && image[:tempfile]
      filename = "#{SecureRandom.hex}_#{image[:filename]}"
      filepath = File.join('public', 'img', filename)
  
      File.open(filepath, 'wb') do |f|
        f.write(image[:tempfile].read)
      end
  
      image_url = "/img/#{filename}"
    end

    Product.update(name, price, desc, category, sku, image_url, id)
  
    redirect '/product/new'
  end

  # Displays login form.
  #
  # @return [String] Rendered login page
  get '/login' do
    erb :login
  end
  
  # Processes login attempt.
  #
  # @return [void] Redirects to admin or products page based on user role
  # @raise [RuntimeError] If credentials are invalid
  post '/login' do
    username = params[:username]
    password = params[:password]
  
    user = User.index_with_username(username)
    halt 401, 'Invalid username or password' unless user && BCrypt::Password.new(user['password']) == password
  
    session[:user_id] = user['id']
    redirect user['admin'].to_i == 1 ? '/product/new' : '/product'
  end
  
  # Logs out current user.
  #
  # @return [void] Redirects to products page
  post '/logout' do
    session.clear 
    redirect '/product'
  end
  
  # Displays user registration form.
  #
  # @return [String] Rendered registration form
  get '/user/new' do
    session[:email_taken] ||= false
    session[:username_taken] ||= false
    erb :"user/new"
  end
  
  # Creates a new user account.
  #
  # @return [void] Redirects to products page or back to form if errors
  post '/user' do
    email = params['email']
    username = params['username']
    password = params['password']
  
    password_hashed = BCrypt::Password.create(password)
  
    existing_user = User.existing_user(email, username)
  
    if existing_user
      session[:email_taken] = existing_user['email'] == email
      session[:username_taken] = existing_user['username'] == username
      redirect '/user/new'
    else
      User.insert_new(email, username, password_hashed)
      session[:email_taken] = false
      session[:username_taken] = false
      redirect '/product'
    end
  end
end
