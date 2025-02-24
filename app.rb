# frozen_string_literal: true

class App < Sinatra::Base
  get '/' do
    redirect('/products')
    if session[:user_id]
      erb(:"admin/index")
    else
      erb :index
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
    puts "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa"
    p @session_username = db.execute('SELECT username FROM users WHERE id = ?', session[:user_id].to_i).first
    puts "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa"
    if session[:user_id]
      @products = db.execute('SELECT * FROM equipment')
      erb(:"admin/index")
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
    @products = db.execute('SELECT * FROM equipment')
    erb(:index)
  end

  post '/products' do
    db.execute('INSERT INTO equipment (article, description, category) VALUES(?,?,?)',
               [
                 params['article'],
                 params['description'],
                 params['category']
               ])
    redirect('/admin')
  end

  post '/products/:id/delete' do |id|
    db.execute('DELETE FROM equipment WHERE Id = ?', id)
    redirect '/admin'
  end

  get '/products/:id/edit' do |id|
    @product = db.execute('SELECT * FROM equipment WHERE Id = ?', id).first
    erb(:"admin/change")
  end

  post '/products/:id/update' do |id|
    db.execute("
      UPDATE equipment
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
      redirect '/admin'
    else
      status 401
      redirect '/unauthorized'
    end
  end



  get '/signup' do
    erb(:signup)
  end

  post '/signup' do
    params[:username]
    password_hashed = BCrypt::Password.create(params[:password])
    db.execute('INSERT INTO users (email, username, password) VALUES(?,?,?)',
               [
                 params['email'],
                 params['username'],
                 password_hashed
               ])
    redirect '/products'
  end
end
