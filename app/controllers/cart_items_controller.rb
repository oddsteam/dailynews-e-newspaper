class CartItemsController < ApplicationController
  before_action :store_checkout_location, only: [ :create ]

  def create
    if member_signed_in? && current_user.subscriptions.any?(&:active?)
      redirect_to library_path, notice: "You already have an active subscription. Enjoy reading!"
      return
    end

    product = Product.find_by(sku: params[:sku])

    if product.blank?
      redirect_to root_path, alert: "Product not found"
      return
    end

    cart = Cart.find_or_create_by(user_id: current_user.id)

    cart_item = cart.cart_item || cart.build_cart_item
    cart_item.product = product

    if cart_item.save
      redirect_to checkout_path, notice: "Product added to cart"
    else
      redirect_to root_path, alert: "Failed to add product to cart"
    end
  end

  # def update
  #   cart_item = current_user.cart&.cart_item

  #   if cart_item.blank?
  #     redirect_to root_path, alert: "Cart item not found"
  #     return
  #   end

  #   product = Product.find_by(sku: params[:sku])

  #   if product.blank?
  #     redirect_to checkout_path, alert: "Product not found"
  #     return
  #   end

  #   if cart_item.update(product: product)
  #     redirect_to checkout_path, notice: "Switched to #{product.title}"
  #   else
  #     redirect_to checkout_path, alert: "Failed to update cart"
  #   end
  # end

  private

  def store_checkout_location
    return if member_signed_in?

    script_name = Rails.application.credentials.dig(:turbo, :root) || "/"
    checkout_url = checkout_path(script_name: script_name)

    store_location_for(:member, checkout_url)
  end
end
