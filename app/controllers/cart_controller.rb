# controllers/cart_controller.rb
# Handles shopping cart operations and checkout process.
class CartController < BaseController
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
end