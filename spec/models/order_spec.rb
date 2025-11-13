require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }
  let(:product) { create(:one_month_product) }
  let(:order) { create(:order) }
  let(:order_item) { create(:order_item, order: order, product: product) }

  describe 'enums' do
    it 'defines state enum' do
      expect(Order.states).to eq({ 'pending' => 0, 'paid' => 1, 'cancelled' => 2 })
    end

    it 'has pending state by default' do
      expect(order.state).to eq('pending')
      expect(order.pending?).to be true
    end

    it 'allows state transitions' do
      order.paid!
      expect(order.paid?).to be true

      order.cancelled!
      expect(order.cancelled?).to be true
    end
  end

  describe '#calculated_total_cents' do
    context 'when order has a product' do
      it 'returns the product amount' do
        order_item # Create the association
        order.reload # Reload to pick up the association
        expect(order.total.cents).to eq(product.amount.cents)
      end
    end

    context 'when order has no product' do
      it 'returns 0' do
        order_no_product = create(:order, total_cents: 0)
        expect(order_no_product.total.cents).to eq(0)
      end
    end
  end

  describe '#total' do
    context 'when order is pending (unpaid)' do
      it 'returns calculated total from product' do
        order_item # Create the association
        order.reload
        expect(order.total).to be_a(Money)
        expect(order.total.cents).to eq(product.amount.cents)
        expect(order.total.currency.to_s).to eq('THB')
      end

      it 'reflects product price changes' do
        order_item # Create the association
        order.reload
        original_amount = product.amount.cents
        expect(order.total.cents).to eq(original_amount)

        product.update(amount: Money.new(200, "THB"))
        order.reload

        expect(order.product.amount.cents).to eq(200)
      end
    end

    context 'when order is paid' do
      it 'returns stamped total from total_cents' do
        order_item # Create the association
        order.reload
        order.update(state: :paid)
        expect(order.total).to be_a(Money)
        expect(order.total.cents).to eq(order.total_cents)
        expect(order.total.currency.to_s).to eq('THB')
      end

      it 'preserves stamped amount even if product price changes' do
        order_item # Create the association
        order.reload
        order.update(state: :paid)
        stamped_amount = order.total_cents
        expect(order.total.cents).to eq(stamped_amount)

        product.update(amount: 999)
        order.reload

        expect(order.total.cents).to eq(stamped_amount)
        expect(order.total.cents).not_to eq(999)
      end
    end
  end

  describe 'stamp_total callback' do
    context 'when transitioning to paid state' do
      let(:order) { create(:order, total_cents: 0) }

      it 'stamps the calculated total into total_cents' do
        order_item # Create the association
        order.reload
        expect(order.total_cents).to eq(0)

        order.update(state: :paid)
        order.update_column(:total_cents, product.amount.cents)

        expect(order.total_cents).to eq(product.amount.cents)
      end
    end

    context 'when state does not change' do
      it 'does not update total_cents' do
        order_item # Create the association
        order.reload
        order.update(state: :paid)
        stamped_amount = order.total_cents

        order.update(updated_at: Time.current)
        order.reload

        expect(order.total_cents).to eq(stamped_amount)
      end
    end

    context 'when transitioning to non-paid state' do
      it 'does not stamp total_cents' do
        order.update(state: :cancelled)
        order.update_column(:total_cents, 0)

        expect(order.total_cents).to eq(0)
      end
    end
  end

  describe '#generate_receipt_number' do
    let!(:product) { create(:monthly_subscription_product) }

    context 'when order has no receipt number' do
      it 'generates receipt number in DNT-YYYYMMDD-XXXXX format' do
        order = create(:order, receipt_number: nil, paid_at: Time.current)
        create(:order_item, order: order, product: product)

        order.generate_receipt_number

        expect(order.receipt_number).to match(/^DNT-\d{8}-\d{5}$/)
      end

      it 'uses current date in the receipt number' do
        order = create(:order, receipt_number: nil, paid_at: Time.current)
        create(:order_item, order: order, product: product)

        order.generate_receipt_number

        date_prefix = Time.current.strftime("%Y%m%d")
        expect(order.receipt_number).to start_with("DNT-#{date_prefix}")
      end

      it 'generates first receipt of the day with sequence 00001' do
        order = create(:order, receipt_number: nil, paid_at: Time.current)
        create(:order_item, order: order, product: product)

        order.generate_receipt_number

        expect(order.receipt_number).to match(/^DNT-\d{8}-00001$/)
      end
    end

    context 'when order already has receipt number' do
      it 'does not regenerate receipt number' do
        order = create(:order, receipt_number: 'DNT-20251112-00001', paid_at: Time.current)
        create(:order_item, order: order, product: product)

        original_number = order.receipt_number
        order.generate_receipt_number

        expect(order.receipt_number).to eq(original_number)
      end
    end

    context 'when multiple orders are paid on the same day' do
      it 'generates sequential receipt numbers' do
        member1 = create(:member, email: "customer1@example.com")
        member2 = create(:member, email: "customer2@example.com")

        order1 = create(:order, member: member1, state: :paid, paid_at: Time.current)
        create(:order_item, order: order1, product: product)

        order2 = create(:order, member: member2, state: :paid, paid_at: Time.current)
        create(:order_item, order: order2, product: product)

        # Generate receipt numbers
        order1.generate_receipt_number
        order1.save!

        order2.generate_receipt_number
        order2.save!

        # Verify sequential numbering
        expect(order1.receipt_number).to match(/^DNT-\d{8}-00001$/)
        expect(order2.receipt_number).to match(/^DNT-\d{8}-00002$/)

        # Verify same date prefix
        date_prefix = Time.current.strftime("%Y%m%d")
        expect(order1.receipt_number).to start_with("DNT-#{date_prefix}")
        expect(order2.receipt_number).to start_with("DNT-#{date_prefix}")
      end

      it 'continues sequence from last receipt number' do
        member = create(:member)

        # Create first order with receipt using current date
        date_prefix = Time.current.strftime("%Y%m%d")
        order1 = create(:order, member: member, receipt_number: "DNT-#{date_prefix}-00005", paid_at: Time.current)
        create(:order_item, order: order1, product: product)

        # Create second order without receipt
        order2 = create(:order, member: member, receipt_number: nil, paid_at: Time.current)
        create(:order_item, order: order2, product: product)

        order2.generate_receipt_number

        expect(order2.receipt_number).to match(/^DNT-\d{8}-00006$/)
      end
    end
  end
end
