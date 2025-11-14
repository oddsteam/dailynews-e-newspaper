require 'rails_helper'

RSpec.describe Newspaper, type: :model do
  let(:newspaper1) { create(:newspaper, created_at: Date.today) }
  let(:newspaper2) { create(:newspaper, created_at: Date.tomorrow) }

  it "newspaper can order by created_at date" do
    assert_equal Newspaper.order_by_created_at, [ newspaper1, newspaper2 ]
  end

  it "filter newspapers by month" do
    newspaper_jan = create(:newspaper, published_at: Date.new(2025, 1, 1))
    newspaper_feb = create(:newspaper, published_at: Date.new(2025, 2, 1))

    january_newspapers = Newspaper.filter_by_month("1", nil)
    february_newspapers = Newspaper.filter_by_month("2", nil)
    all_newspapers = Newspaper.filter_by_month(nil, nil)

    expect(january_newspapers).to eq([ newspaper_jan ])
    expect(january_newspapers).not_to eq([ newspaper_feb ])

    expect(february_newspapers).to eq([ newspaper_feb ])
    expect(february_newspapers).not_to eq([ newspaper_jan ])

    expect(all_newspapers).to eq [ newspaper_jan, newspaper_feb ]
  end

  it "filter newspapers by year" do
    newspaper_jan2023 = create(:newspaper, published_at: Date.new(2023, 1, 1))
    newspaper_jan2024 = create(:newspaper, published_at: Date.new(2024, 1, 1))
    newspaper_jan2025 = create(:newspaper, published_at: Date.new(2025, 1, 1))

    newspapers_2023 = Newspaper.filter_by_month(nil, 2023)
    newspapers_2024 = Newspaper.filter_by_month(nil, 2024)
    newspapers_2025 = Newspaper.filter_by_month(nil, 2025)
    all_newspapers = Newspaper.filter_by_month(nil, nil)

    expect(newspapers_2023).to eq([ newspaper_jan2023 ])
    expect(newspapers_2023).not_to eq([ newspaper_jan2024, newspaper_jan2025 ])

    expect(newspapers_2024).to eq([ newspaper_jan2024 ])
    expect(newspapers_2024).not_to eq([ newspaper_jan2023, newspaper_jan2025 ])

    expect(newspapers_2025).to eq([ newspaper_jan2025 ])
    expect(newspapers_2025).not_to eq([ newspaper_jan2023, newspaper_jan2024 ])

    expect(all_newspapers).to eq [ newspaper_jan2023, newspaper_jan2024, newspaper_jan2025 ]
  end
end
