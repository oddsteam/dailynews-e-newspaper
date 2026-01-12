require 'rails_helper'

RSpec.describe Product, type: :model do
  let!(:one_month_product) { create(:one_month_product) }
  let(:member) { create(:member) }
  let(:product) { create(:monthly_subscription_product, amount: nil) }
  TAX_RATE = 0.07

  it "not create then title is nil" do
    product = build(:product, title: nil)
    expect(product).not_to be_valid
    expect(product.errors[:title]).to include("ไม่สามารถว่างได้")
  end

  it "not create then sku is nil" do
    product = build(:product, sku: nil)
    expect(product).not_to be_valid
    expect(product.errors[:sku]).to include("ไม่สามารถว่างได้")
  end

  it "is invalid with a duplicate title" do
    product = build(:product, title: one_month_product.title)
    expect(product).not_to be_valid
    expect(product.errors[:title]).to include("ชื่อผู้ใช้ซ้ำกับบัญชีที่มีอยู่แล้วในระบบ กรุณาเปลี่ยนชื่อ")
  end

  it "is invalid with a duplicate sku" do
    product = build(:product, sku: one_month_product.sku)
    expect(product).not_to be_valid
    expect(product.errors[:sku]).to include("ชื่อผู้ใช้ซ้ำกับบัญชีที่มีอยู่แล้วในระบบ กรุณาเปลี่ยนชื่อ")
  end

  it "is valid with all required attributes" do
    product = build(:product, title: "New Product", amount: 100, sku: "NEW_SKU")
    expect(product).to be_valid
  end

  context "product price exists" do
    let(:product_have_amount) { create(:product) }

    it "should be base price equal than product price / 1.07" do
      cal = product_have_amount.amount.cents / 1.07
      expect(product_have_amount.base_price).to eq(Money.new(cal.round, "THB"))
    end

    it "should be tax amount equal than amount - base price" do
      expect(product_have_amount.tax_amount).to eq(product_have_amount.amount.cents - product_have_amount.base_price)
    end
  end

  context "product price does not exists" do
    it "should be base price equal than 0 when not have product price" do
      expect(product.base_price).to eq(Money.new(0, "THB"))
    end

    it "should be tax amount equal than 0 when not have product price" do
      expect(product.tax_amount).to eq(Money.new(0, "THB"))
    end
  end

  it "should be return tax rate percentage" do
    expect(product.tax_rate_percentage).to eq((TAX_RATE * 100).to_i)
  end
end
