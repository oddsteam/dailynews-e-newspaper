class OrdersController < ApplicationController
  before_action :set_order, only: %i[ verify complete ]

  # POST /orders or /orders.json
  def create
    @cart = current_user.cart
    @product = @cart&.cart_item&.product

    unless @product
      redirect_to root_path, alert: "No product in cart" and return
    end

    @order = current_user.orders.create(order_params)

    if @order.valid?
      # Link order to product via order_item
      @order.create_order_item(product: @product)

      # find existing omise customer by email
      if current_user.omise_customer_id.present?
        customer = Omise::Customer.retrieve(current_user.omise_customer_id)
        customer.update(card: order_params[:token])
      else
        # second step, we will create omise customer for future use
        customer = Omise::Customer.create({
          email: current_user.email,
          description: "#{current_user.email} - #{current_user.id}",
          card: order_params[:token]
        })
        current_user.update(omise_customer_id: customer.id)
      end

      # first step, we will be using omise token for creating a charge
      charge = Omise::Charge.create({
        amount: (order_params[:total_cents].to_i),
        currency: "thb",
        customer: customer.id,
        capture: false,
        return_uri: verify_order_url(@order),
        recurring_reason: "subscription"
      })

      @order.update charge_id: charge.id
      redirect_to charge.authorize_uri, allow_other_host: true
    else
      p @order.errors.full_messages
    end
  end

  def verify
    charge = Omise::Charge.retrieve(@order.charge_id)
    charge.capture

    if charge.paid
      @order.paid!

      # Create subscription for the user
      if CreateSubscriptionForOrder.new(@order).perform
        # Clear the user's cart after successful order
        ClearCurrentUserCart.new(@order.member).perform
        redirect_to complete_order_path(@order)
      else
        redirect_to root_path, alert: "Payment successful but failed to create subscription. Please contact support."
      end
    else
      # Mark order as cancelled when payment fails
      @order.cancelled!

      # Recreate cart with the product from failed order so user can retry
      cart = Cart.find_or_create_by(user_id: @order.member.id)
      cart_item = cart.cart_item || cart.build_cart_item
      cart_item.product = @order.product
      cart_item.save

      redirect_to checkout_path, alert: "Payment failed. Please try again."
    end
  end

  def complete
  end

  private
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def order_params
      permitted = params.expect(order: [ :token, :total_cents ])

      # Calculate sub_total_cents (base price before 7% VAT) from tax-included total
      if permitted[:total_cents].present?
        total_cents = permitted[:total_cents].to_i
        permitted[:sub_total_cents] = (total_cents / 1.07).round
      end

      permitted
    end
end
