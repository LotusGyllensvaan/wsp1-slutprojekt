class App < Sinatra::Base
  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
    set :sessions, expire_after: 60 * 60 * 24 * 7
    set :erb, escape_html: true
  end

  before do
    params.each do |key, value|
      params[key] = Rack::Utils.escape_html(value) if value.is_a?(String)
    end
    @user = user
    unless ['/login', '/signup', '/unauthorized'].include?(request.path_info)
      ensure_shopping_session
    end
  end

  def user
    db.execute('SELECT * FROM users WHERE id = ?', session[:user_id].to_i).first
  end

  def db
    return @db if @db

    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true
    @db
  end

  def ensure_shopping_session
    return if session[:shopping_session_id]

    user_id = session[:user_id] || nil
    db.execute("INSERT INTO shopping_session (user_id, total, created_at, modified_at) VALUES (?, ?, CURRENT_TIMESTAMP, NULL)",
               [user_id, 0.00])

    session[:shopping_session_id] = db.last_insert_row_id
  end

  get '/' do
    redirect('/products')
    erb session[:user_id] ? :"admin/index" : :"products/index"
  end

  get '/admin' do
    @user = user
    if @user && @user['admin'].to_i == 1
      @products = db.execute('SELECT * FROM product')
      erb :"admin/index"
    else
      status 401
      redirect '/unauthorized'
    end
  end

  get '/unauthorized' do
    erb :unauthorized
  end

  get '/products' do
    ensure_shopping_session
    @user = user
    @products = db.execute('SELECT * FROM product')
    erb :"products/index"
  end

  post '/products' do
    image = params[:image]
    image_filename = nil
  
    if image && image[:filename]
      uploads_dir = File.join(settings.public_folder, 'img')
      FileUtils.mkdir_p(uploads_dir) # Create the folder if it doesn't exist
  
      image_filename = "#{Time.now.to_i}_#{image[:filename]}"
      image_path = File.join(uploads_dir, image_filename)
  
      # Save the uploaded file
      File.open(image_path, 'wb') do |f|
        f.write(image[:tempfile].read)
      end
    end
  
    # Save product to database, including the relative image path
    db.execute(
      'INSERT INTO product (name, price, desc, category, sku, image_url) VALUES (?, ?, ?, ?, ?, ?)',
      [
        params['article'],
        params['value'],
        params['description'],
        params['category'],
        params['SKU'],
        image_filename ? "img/#{image_filename}" : nil
      ]
    )
  
    redirect('/admin')
  end
  

  get '/products/:id' do |id|
    @product = db.execute('SELECT * FROM product WHERE id = ?', id).first
    erb :"products/show"
  end

  post '/products/:id/delete' do |id|
    db.execute('DELETE FROM product WHERE Id = ?', id)
    redirect '/admin'
  end

  get '/products/:id/edit' do |id|
    @product = db.execute('SELECT * FROM product WHERE Id = ?', id).first
    erb :"products/change"
  end
  
  post '/products/:id/update' do |id|
    name = params['name']
    desc = params['desc']
    price = params['price']
    category = params['category']
    sku = params['sku']
  
    image = params['image']
    image_url = nil
  
    # Save the image if one was uploaded
    if image && image[:filename] && image[:tempfile]
      filename = "#{SecureRandom.hex}_#{image[:filename]}"
      filepath = File.join('public', 'img', filename)
  
      File.open(filepath, 'wb') do |f|
        f.write(image[:tempfile].read)
      end
  
      image_url = "/img/#{filename}"
    end
  
    if image_url
      db.execute("UPDATE product SET name = ?, price = ?, desc = ?, category = ?, sku = ?, image_url = ? WHERE id = ?",
                 [name, price, desc, category, sku, image_url, id])
    else
      db.execute("UPDATE product SET name = ?, price = ?, desc = ?, category = ?, sku = ? WHERE id = ?",
                 [name, price, desc, category, sku, id])
    end
  
    redirect '/admin'
  end
  

  post '/cart/:id' do |id|
    quantity = params['quantity'].to_i

    if quantity > 0
      cart_item_values = [session[:shopping_session_id], id, quantity]
      db.execute('INSERT INTO cart_item (session_id, product_id, quantity) VALUES (?, ?, ?)', cart_item_values)
    end
    redirect '/products'
  end

  get '/cart' do
    @cart_products = db.execute('
      SELECT p.id AS product_id, p.name, p.desc, p.SKU, p.category, p.price, ci.quantity
      FROM cart_item ci
      JOIN product p ON ci.product_id = p.id
      WHERE ci.session_id = ?',
      [session[:shopping_session_id]])
    erb :cart
  end

  post '/checkout' do
    session_id = session[:shopping_session_id]
    cart_items = db.execute("SELECT product_id, quantity FROM cart_item WHERE session_id = ?", [session_id])

    total_amount = cart_items.reduce(0) do |sum, item|
      product = db.get_first_row("SELECT price FROM product WHERE id = ?", [item['product_id']])
      sum + (product['price'] * item['quantity'])
    end

    db.execute("INSERT INTO payment_details (amount, provider, status, created_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)",
               [total_amount, 'credit_card', 'pending'])

    payment_id = db.last_insert_row_id
    user_id = session[:user_id]

    db.execute("INSERT INTO order_details (user_id, total, payment_id, created_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)",
               [user_id, total_amount, payment_id])

    order_id = db.last_insert_row_id

    cart_items.each do |item|
      db.execute("INSERT INTO order_items (order_id, product_id, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)",
                 [order_id, item['product_id']])
    end

    db.execute("DELETE FROM cart_item WHERE session_id = ?", [session_id])

    redirect "/order/confirmation/#{order_id}"
  end

  get '/order/confirmation/:order_id' do |order_id|
    order = db.get_first_row("SELECT * FROM order_details WHERE id = ?", [order_id])
    halt 404, "Order not found" unless order

    payment = db.get_first_row("SELECT * FROM payment_details WHERE id = ?", [order['payment_id']])
    items = db.execute("SELECT product.name, product.price, order_items.created_at
                        FROM order_items
                        JOIN product ON product.id = order_items.product_id
                        WHERE order_items.order_id = ?", [order_id])

    erb :order_confirmation, locals: { order: order, payment: payment, items: items }
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    username = params[:username]
    password = params[:password]

    user = db.execute("SELECT * FROM users WHERE username = ?", username).first
    halt 401, 'Invalid username or password' unless user && BCrypt::Password.new(user['password']) == password

    session[:user_id] = user['id']
    redirect user['admin'].to_i == 1 ? '/admin' : '/products'
  end

  post '/logout' do
    session.clear 
    redirect '/products'
  end

  get '/signup' do
    session[:email_taken] ||= false
    session[:username_taken] ||= false
    erb :signup
  end
  

  post '/signup' do
    email = params['email']
    username = params['username']
    password = params['password']
  
    password_hashed = BCrypt::Password.create(password)
  
    existing = db.execute(
      'SELECT email, username FROM users WHERE email = ? OR username = ?',
      [email, username]
    ).first
  
    if existing
      session[:email_taken] = existing['email'] == email
      session[:username_taken] = existing['username'] == username
      redirect '/signup'
    else
      db.execute('INSERT INTO users (email, username, password, admin) VALUES(?, ?, ?, ?)',
                 [email, username, password_hashed, 0])
      session[:email_taken] = false
      session[:username_taken] = false
      redirect '/products'
    end
  end
  
end