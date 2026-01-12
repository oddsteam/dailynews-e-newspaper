require 'rails_helper'

RSpec.describe Subscription, type: :model do
  it "not create then start_date is nil" do
    subscription = build(:subscription, start_date: nil)
    expect(subscription).not_to be_valid
    expect(subscription.errors[:start_date]).to include("ไม่สามารถว่างได้")
  end

  it "not create then end_date is nil" do
    subscription = build(:subscription, end_date: nil)
    expect(subscription).not_to be_valid
    expect(subscription.errors[:end_date]).to include("ไม่สามารถว่างได้")
  end

  it "can create subscription with valid data" do
    subscription = create(:subscription)
    expect(subscription).to be_valid
    expect(Subscription.first.start_date).to eq(subscription.start_date)
  end

  it "subscription is active" do
    subscription = build(:subscription)
    expect(subscription.active?).to eq(true)
  end

  it "subscription is inactive" do
    subscription = build(:subscription, start_date: 2.months.ago, end_date: 1.month.ago)
    expect(subscription.active?).to eq(false)
  end
end
