# frozen_string_literal: true

class App < Sinatra::Base

  def user
    db.execute('SELECT * FROM users WHERE id = ?', session[:user_id].to_i).first
  end

  get '/' do
    redirect('/products')
    if session[:user_id]
      erb(:"admin/index")
    else
      erb :"products/index"
    end
  end

  def db
    return @db if @db

    @db = SQLite3::Database.new('db/database.sqlite')
    @db.results_as_hash = true

    @db
  end

  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
    set :sessions, expire_after: 3600
  end

  get '/admin' do
    @user = user

    if @user['admin'].to_i == 1
      @products = db.execute('SELECT * FROM products')
      erb :"admin/index"
    else
      p '/admin : Access denied.'
      status 401
      redirect '/unauthorized'
    end
  end

  get '/unauthorized' do
    erb(:unauthorized)
  end

  get '/products' do
    @user = user
    @products = db.execute('SELECT * FROM products')
    erb :"products/index"
  end

  post '/products' do
    db.execute('INSERT INTO products (article, value, description, category) VALUES(?,?,?,?)',
               [
                 params['article'],
                 params['value'],
                 params['description'],
                 params['category']
               ]
    )
    redirect('/admin')
  end

  get '/products/:id' do |id|
    @product = db.execute('SELECT * FROM products WHERE id = ?', id).first
    erb :"products/show"
  end

  post '/products/:id/delete' do |id|
    db.execute('DELETE FROM products WHERE Id = ?', id)
    redirect '/admin'
  end

  get '/products/:id/edit' do |id|
    @product = db.execute('SELECT * FROM products WHERE Id = ?', id).first
    erb(:"products/change")
  end

  post '/products/:id/update' do |id|
    db.execute("
      UPDATE products
      SET
          article = ?,
          description = ?,
          category = ?
      WHERE
          id = ?
      ",
               [
                 params['article'],
                 params['description'],
                 params['category'],
                 id
               ])
    redirect('/admin')
  end

  get '/login' do
    @logging_in = true
    erb(:login)
  end

  post '/login' do
    request_username = params[:username]
    request_plain_password = params[:password]

    user = db.execute("SELECT *
                FROM users
                WHERE username = ?",
                      request_username).first

    unless user
      p '/login : Invalid username.'
      status 401
      redirect '/unauthorized'
    end

    db_id = user['id'].to_i
    db_password_hashed = user['password'].to_s

    # Create a BCrypt object from the hashed password from db
    bcrypt_db_password = BCrypt::Password.new(db_password_hashed)
    # Check if the plain password matches the hashed password from db
    if bcrypt_db_password == request_plain_password
      session[:user_id] = db_id
      redirect (user['admin'].to_i == 1 ? '/admin' : '/products')
    else
      status 401
      redirect '/unauthorized'
    end
  end

  get '/signup' do
    p session[:email_taken] ||= false
    p session[:username_taken] ||= false
    @signing_in = true
    erb :signup
  end

  post '/signup' do
    session[:email_taken] = false
    session[:username_taken] = false

    password_hashed = BCrypt::Password.create(params[:password])
    requested_email = params['email']
    requested_username = params['username']

    requested_credentials = [requested_email, requested_username]
    new_user = [requested_email, requested_username, password_hashed, 0]

    existing = db.execute('SELECT email, username FROM users WHERE email = ? OR username = ?', requested_credentials).first
    if existing
      session[:email_taken] = true if existing['email']
      session[:username_taken] = true if existing['username']
      redirect '/signup'
    else
      db.execute('INSERT INTO users (email, username, password, admin) VALUES(?,?,?,?)', new_user)
      session[:email_taken] = false
      session[:username_taken] = false
    end
    redirect '/products'
  end

  get '/checkout' do
    erb :"checkout"
  end
end
