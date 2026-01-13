class OrdersController < ApplicationController
  before_action :set_order, only: %i[ verify complete receipt ]

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

      begin
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

        # Get the last card added to the customer, which is the one we just added.
        card_id = customer.cards.last.id

        # first step, we will be using omise token for creating a charge
        charge = Omise::Charge.create({
          amount: (order_params[:total_cents].to_i),
          currency: "thb",
          customer: customer.id,
          card: card_id, # Explicitly charge the new card
          capture: false,
          return_uri: verify_order_url(@order),
          recurring_reason: "subscription"
        })

        @order.update charge_id: charge.id
        redirect_to charge.authorize_uri, allow_other_host: true
      rescue Omise::Error => e
        Rails.logger.error "Omise create charge error for order #{@order.id}: #{e.message}"
        @order.cancelled!
        redirect_to payment_failed_checkout_path, alert: "Payment failed: #{e.message}" and return
      end
    else
      p @order.errors.full_messages
    end
  end

  def verify
    charge = Omise::Charge.retrieve(@order.charge_id)
    begin
      charge.capture
    rescue Omise::Error => e
      # If capture fails, it raises an exception. We need to catch it and handle the failure.
      Rails.logger.error "Omise capture error for order #{@order.id}: #{e.message}"
      @order.cancelled!

      # Recreate cart with the product from failed order so user can retry
      cart = Cart.find_or_create_by(user_id: @order.member.id)
      cart_item = cart.cart_item || cart.build_cart_item
      cart_item.product = @order.product
      cart_item.save

      redirect_to payment_failed_checkout_path, alert: "Payment failed: #{e.message}" and return
    end

    if charge.paid
      @order.paid!
      @order.update!(paid_at: Time.current)

      # Create subscription for the user
      if CreateSubscriptionForOrder.new(@order).perform
        # Generate receipt number and send email
        @order.generate_receipt_number
        @order.save!

        # Send receipt email with PDF attachment
        OrderMailer.receipt_email(@order).deliver_later
        @order.update!(receipt_sent_at: Time.current)

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

      redirect_to payment_failed_checkout_path, alert: "Payment failed. Please try again."
    end
  end

  def complete
  end

  def receipt
    # Check if order belongs to current user
    unless @order.member == current_user
      redirect_to root_path, alert: "Unauthorized access" and return
    end

    # Check if receipt number exists (order is paid)
    unless @order.receipt_number.present?
      redirect_to root_path, alert: "Receipt not available" and return
    end

    # Generate PDF
    pdf = Receipts::SimplifiedReceiptPdf.new(@order)

    # Send PDF as download
    send_data pdf.render,
              filename: "receipt-#{@order.receipt_number}.pdf",
              type: "application/pdf",
              disposition: "attachment"
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
