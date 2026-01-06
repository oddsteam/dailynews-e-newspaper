require "rails_helper"

describe "User can download receipt", type: :system do
  include OmiseHelpers

  let!(:company) do
    Company.create!(
      name: "Daily News Company",
      address_1: "123 Main Street",
      sub_district: "Sub District",
      district: "District",
      province: "Bangkok",
      postal_code: "10000",
      country: "Thailand",
      phone_number: "02-123-4567",
      email: "info@dailynews.com",
      tax_id: "1234567890123"
    )
  end

  let!(:product) { create(:monthly_subscription_product, title: "Monthly Subscription") }

  describe "receipt access control" do
    context "when user is not signed in" do
      let!(:order) do
        member = create(:member)
        create(:order, member: member, state: :paid, receipt_number: "DNT-20251112-00001", paid_at: Time.current)
      end

      it "redirects to root when trying to access receipt directly" do
        visit receipt_order_path(order)

        expect(page).to have_current_path(root_path)
        expect(page).to have_content("Unauthorized access")
      end
    end

    context "when member tries to access another user's receipt" do
      let!(:member_a) { create(:member, email: "membera@example.com") }
      let!(:member_b) { create(:member, email: "memberb@example.com") }

      let!(:order_a) do
        create(:order, member: member_a, state: :paid, receipt_number: "DNT-20251112-00001", paid_at: Time.current).tap do |order|
          create(:order_item, order: order, product: product)
        end
      end

      let!(:order_b) do
        create(:order, member: member_b, state: :paid, receipt_number: "DNT-20251112-00002", paid_at: Time.current).tap do |order|
          create(:order_item, order: order, product: product)
        end
      end

      before { login_as_user(member_a) }

      it "prevents access with unauthorized error" do
        visit receipt_order_path(order_b)

        expect(page).to have_current_path(root_path)
        expect(page).to have_content("Unauthorized access")
      end
    end

    context "when member has pending order without receipt" do
      let!(:member) { create(:member) }
      let!(:pending_order) do
        create(:order, member: member, state: :pending, receipt_number: nil).tap do |order|
          create(:order_item, order: order, product: product)
        end
      end

      before { login_as_user(member) }

      it "shows receipt not available message" do
        visit receipt_order_path(pending_order)

        expect(page).to have_current_path(root_path)
        expect(page).to have_content("Receipt not available")
      end
    end
  end

  describe "receipt download functionality" do
    context "when member has completed order with receipt" do
      let!(:member) { create(:member) }
      let!(:subscription) do
        create(:subscription,
          member: member,
          start_date: Date.today,
          end_date: Date.today + 30.days)
      end
      let!(:paid_order) do
        create(:order,
          member: member,
          state: :paid,
          receipt_number: "DNT-20251112-00001",
          paid_at: Time.current,
          total_cents: 35000,
          sub_total_cents: 32700).tap do |order|
          create(:order_item, order: order, product: product)
          order.update!(subscription: subscription)
        end
      end

      before { login_as_user(member) }

      it "shows download receipt link on order complete page" do
        visit complete_order_path(paid_order)

        expect(page).to have_content("Thank You for Your Purchase")
        expect(page).to have_link("Download Receipt", href: receipt_order_path(paid_order))
      end

      it "shows download receipt link in purchase history" do
        visit account_purchases_path

        expect(page).to have_content("Purchase history")
        expect(page).to have_content(product.title)
        expect(page).to have_content("PAID")
        expect(page).to have_link("Download Receipt", href: receipt_order_path(paid_order))
      end

      it "can access receipt download endpoint from complete page" do
        visit complete_order_path(paid_order)

        # Verify link exists and points to correct path
        receipt_link = find_link("Download Receipt")
        expect(receipt_link[:href]).to include(receipt_order_path(paid_order))

        # Visit receipt path directly (clicking would trigger download)
        visit receipt_order_path(paid_order)

        # If we get here without error, receipt was generated successfully
        # (PDF generation doesn't raise error)
      end

      it "can access receipt download endpoint from purchase history" do
        visit account_purchases_path

        # Verify link exists
        receipt_link = find_link("Download Receipt")
        expect(receipt_link[:href]).to include(receipt_order_path(paid_order))

        # Visit receipt path directly
        visit receipt_order_path(paid_order)

        # If we get here without error, receipt was generated successfully
      end
    end
  end

  describe "receipt generation after successful payment" do
    context "when member completes purchase and payment succeeds" do
      let!(:member) { create(:member) }

      before do
        login_as_user(member)
      end

      it "shows receipt download option after successful payment" do
        visit root_path
        click_button "subscribe"

        accept_terms
        click_link_or_button "ดำเนินการต่อ"
        user_pays_with_omise(token: "tokn_test_5mokdpoelz84n3ai99l")

        # User sees success page with download link
        expect(page).to have_content("Thank You for Your Purchase")
        expect(page).to have_link("Download Receipt")

        # User navigates to purchase history
        visit account_purchases_path

        expect(page).to have_content("Purchase history")
        expect(page).to have_content("PAID")
        expect(page).to have_link("Download Receipt")
      end
    end

    context "when payment fails" do
      let!(:member) { create(:member) }

      before do
        login_as_user(member)
      end

      it "does not show receipt download option for failed payment" do
        visit root_path
        click_button "subscribe"

        accept_terms
        click_link_or_button "ดำเนินการต่อ"
        user_pays_with_omise_but_fails

        expect(page).to have_current_path(checkout_path)
        expect(page).to have_content("Payment failed. Please try again.")

        # User navigates to purchase history to check
        visit account_purchases_path

        expect(page).to have_content("Purchase history")
        expect(page).to have_content("CANCELLED")
        expect(page).not_to have_link("Download Receipt")
      end
    end
  end
end
