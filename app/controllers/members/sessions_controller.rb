# frozen_string_literal: true

class Members::SessionsController < Devise::SessionsController
  include TransfersGuestCart

  # POST /members/sign_in
  def create
    super do |member|
      # Transfer guest cart to member after successful sign-in
      transfer_guest_cart_to_member(member) if member.persisted?
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def destroy
    super
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
