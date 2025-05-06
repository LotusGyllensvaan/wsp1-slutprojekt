# controllers/product_controller.rb
# Manages product display and CRUD operations (admin only).
class ProductController < BaseController
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
    @product = Product.index_with_id(id)
    p @active_discounts = Product_discount.active_discounts(@product['id'])
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
end