# controllers/order_controller.rb
# Handles order confirmation and display.
class OrderController < BaseController
  # Shows order confirmation details.
  #
  # @param order_id [Integer] Order ID to display
  # @return [String] Rendered order confirmation page
  # @raise [RuntimeError] If order is not found
  get '/order/confirmation/:order_id' do |order_id|
    order = Order_details.index_with_id(order_id)
    halt 404, "Order not found" unless order
  
    payment = Payment_details.index_with_id(order['payment_id'])
    purchases = Order_item.purchases(order_id)
    erb :order_confirmation, locals: { order: order, payment: payment, purchases: purchases }
  end
end