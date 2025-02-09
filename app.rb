class App < Sinatra::Base

    get '/' do
        redirect("/home")
    end

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/equipment.sqlite")
        @db.results_as_hash = true
        
        return @db
    end

    get '/home' do
        p @products = db.execute('SELECT * FROM equipment')
        erb(:"index")
    end

    get '/login' do
        erb(:"login")
    end

end
