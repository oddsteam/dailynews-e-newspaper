class Order < ApplicationRecord
  belongs_to :member, foreign_key: :user_id
  has_one :order_item, dependent: :destroy
  has_one :product, through: :order_item
  has_one :subscription, dependent: :destroy

  monetize :total_cents, :sub_total_cents

  enum :state, { pending: 0, paid: 1, cancelled: 2 }

  # Virtual attribute for Omise token (not stored in database)
  attr_accessor :token

  # Tax rate constant (7% VAT)
  TAX_RATE = 0.07

  # Calculate base price (before tax) from tax-included total
  def base_price
    return Money.new(0, "THB") unless total_cents

    base_cents = (total_cents / 1.07).round
    Money.new(base_cents, "THB")
  end

  # Calculate tax amount from tax-included total
  def tax_amount
    return Money.new(0, "THB") unless total_cents

    Money.new(total_cents, "THB") - base_price
  end

  # Get tax rate as percentage
  def tax_rate_percentage
    (TAX_RATE * 100).to_i
  end

  # Generate receipt number in format: DNT-YYYYMMDD-XXXXX
  def generate_receipt_number
    return if receipt_number.present?

    date_prefix = Time.current.strftime("%Y%m%d")

    # Get the last receipt number for today
    last_receipt = Order.where("receipt_number LIKE ?", "DNT-#{date_prefix}-%")
                        .order(receipt_number: :desc)
                        .first

    if last_receipt && last_receipt.receipt_number.present?
      # Extract sequence number and increment
      sequence = last_receipt.receipt_number.split("-").last.to_i + 1
    else
      # Start with 1 for the first receipt of the day
      sequence = 1
    end

    self.receipt_number = "DNT-#{date_prefix}-#{sequence.to_s.rjust(5, '0')}"
  end
end
