# controllers/discount_controller.rb
# Manages product discounts (admin only).
class DiscountController < BaseController
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
end