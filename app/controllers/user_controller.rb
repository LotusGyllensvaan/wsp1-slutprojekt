# controllers/user_controller.rb
# Handles user authentication and registration.
class UserController < BaseController
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