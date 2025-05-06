# controllers/base_controller.rb

# BaseController handles common application setup, session management,
# authorization checks, and shared helper methods.
#
# It inherits from Sinatra::Base to define web application routes
# and configurations for the app.
#
# @example Accessing a protected route
#   get '/admin' do
#     protected!
#     erb :admin_dashboard
#   end
class BaseController < Sinatra::Base
  # Sets the directory where view templates are located.
  set :views, Proc.new { File.join(root, "../views") }

  # Sets the directory where static files are served from.
  set :public_folder, Proc.new { File.join(root, "../../public") }

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
end
