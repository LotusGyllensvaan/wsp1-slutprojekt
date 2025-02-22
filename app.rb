class App < Sinatra::Base

    get '/' do
        redirect("/home")
        if session[:user_id]
            erb(:"admin/index")
        else
            erb :index
        end
    end

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/database.sqlite")
        @db.results_as_hash = true
        
        return @db
    end

    configure do
        enable :sessions
        set :session_secret, SecureRandom.hex(64)
    end

    get '/admin' do
        if session[:user_id]
          erb(:"admin/index")
        else
          p "/admin : Access denied."
          status 401
          redirect '/unauthorized'
        end
    end

    get '/unauthorized' do
        erb(:"unauthorized")
    end

    get '/home' do
        @products = db.execute('SELECT * FROM equipment')
        erb(:"index")
    end

    get '/login' do
        erb(:"login")
    end

    post '/login' do
        request_username = params[:username]
        request_plain_password = params[:password]
    
        user = db.execute("SELECT *
                FROM users
                WHERE username = ?",
                request_username).first
    
        unless user
          p "/login : Invalid username."
          status 401
          redirect '/unauthorized'
        end
    
        db_id = user["id"].to_i
        db_password_hashed = user["password"].to_s
    
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
        erb(:"signup")
      end

      post '/signup' do
        input_username = params[:username]
        password_hashed = BCrypt::Password.create(params[:password])

        db.execute("INSERT INTO users (email, username, password) VALUES(?,?,?)", 
        [
            params['email'], 
            params['username'],
            password_hashed
        ])

        redirect '/home'
      end

    end
