require "rails_helper"

RSpec.describe OrdersHelper, type: :helper do
  describe "#order_number" do
    let(:date) { Time.zone.parse("2026-01-08 10:30:00") }

    context "when order has id and created_at" do
      let(:order) { double(id: 1, created_at: date) }

      it "returns formatted order number" do
        expect(helper.order_number(order))
          .to eq("DNT-20260108-00001")
      end
    end

    context "when order has a different id" do
      let(:order) { double(id: 42, created_at: date) }

      it "pads id with leading zeros" do
        expect(helper.order_number(order))
          .to eq("DNT-20260108-00042")
      end
    end

    context "when custom prefix is provided" do
      let(:order) { double(id: 7, created_at: date) }

      it "uses custom prefix" do
        expect(helper.order_number(order, prefix: "SUB"))
          .to eq("SUB-20260108-00007")
      end
    end

    context "when created_at is nil" do
      let(:order) { double(id: 3, created_at: nil) }

      it "uses today's date" do
        travel_to(Time.zone.parse("2026-01-08")) do
          expect(helper.order_number(order))
            .to eq("DNT-20260108-00003")
        end
      end
    end

    context "when id is nil" do
      let(:order) { double(id: nil, created_at: date) }

      it "uses 00000 as id part" do
        expect(helper.order_number(order))
          .to eq("DNT-20260108-00000")
      end
    end

    context "when order is nil" do
      it "returns dash" do
        expect(helper.order_number(nil)).to eq("-")
      end
    end
  end
end
