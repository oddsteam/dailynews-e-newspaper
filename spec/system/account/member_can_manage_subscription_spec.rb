require 'rails_helper'

describe "Subscription management", js: true do
  let!(:product) { create(:monthly_subscription_product) }
  let(:member) { create(:member) }

  context "when member has an active subscription" do
    let!(:order) { create(:order, member: member, state: :paid) }
    let!(:order_item) { create(:order_item, order: order, product: product) }
    let!(:subscription) do
      create(:subscription,
        member: member,
        order: order,
        start_date: Date.today,
        end_date: Date.today + 1.month,
        auto_renew: true)
    end

    before do
      login_as_user(member)
    end

    it "can view subscription details" do
      # Navigate to subscriptions page
      find('.user-profile').trigger("click")
      find('[data-testid="subscriptions-payment-btn"]').click

      # Should see subscription details page
      expect(page).to have_content("Subscription Details")

      # Should see subscription information
      within("#my-subscriptions") do
        expect(page).to have_content(product.title)
        expect(page).to have_content("ACTIVE")
        expect(page).to have_content("Subscription:")
      end
    end

    it "shows 'Renews on' when auto-renew is enabled" do
      # Navigate to subscriptions page
      find('.user-profile').trigger("click")
      find('[data-testid="subscriptions-payment-btn"]').click

      # Should show renewal text
      within("#my-subscriptions") do
        expect(page).to have_content("Renews on")
      end
    end

    it "can disable auto-renew" do
      # Navigate to subscriptions page
      find('.user-profile').trigger("click")
      find('[data-testid="subscriptions-payment-btn"]').click

      # Open manage modal
      click_button "MANAGE"

      # Should see auto-renew is enabled
      within("#subscription_modal") do
        expect(page).to have_content("Auto-renew is enabled")

        # Toggle auto-renew off
        find('input[type="checkbox"][name="subscription[auto_renew]"]').trigger("click")
      end

      # Wait for form submission and page reload by checking for success message
      expect(page).to have_content("Auto renew updated successfully.")

      # Verify auto-renew was disabled
      subscription.reload
      expect(subscription.auto_renew).to be false
    end

    it "shows 'Expires on' after disabling auto-renew" do
      # Disable auto-renew first
      subscription.update(auto_renew: false)

      # Navigate to subscriptions page
      visit account_subscriptions_path

      # Should show expiry text
      within("#my-subscriptions") do
        expect(page).to have_content("Expires on")
      end
    end
  end

  context "when member has subscription with auto-renew disabled" do
    let!(:order) { create(:order, member: member, state: :paid) }
    let!(:order_item) { create(:order_item, order: order, product: product) }
    let!(:subscription) do
      create(:subscription,
        member: member,
        order: order,
        start_date: Date.today,
        end_date: Date.today + 1.month,
        auto_renew: false)
    end

    before do
      login_as_user(member)
    end

    it "can enable auto-renew" do
      # Navigate to subscriptions page
      find('.user-profile').trigger("click")
      find('[data-testid="subscriptions-payment-btn"]').click

      # Open manage modal
      click_button "MANAGE"

      # Should see auto-renew is disabled
      within("#subscription_modal") do
        expect(page).to have_content("Auto-renew is disabled")

        # Toggle auto-renew on
        find('input[type="checkbox"][name="subscription[auto_renew]"]').trigger("click")
      end

      # Wait for form submission by checking for success message
      expect(page).to have_content("Auto renew updated successfully.")

      # Verify auto-renew was enabled
      subscription.reload
      expect(subscription.auto_renew).to be true
    end
  end

  context "when member has expired subscription" do
    let!(:order) { create(:order, member: member, state: :paid) }
    let!(:order_item) { create(:order_item, order: order, product: product) }
    let!(:subscription) do
      create(:subscription,
        member: member,
        order: order,
        start_date: 2.months.ago,
        end_date: 1.month.ago,
        auto_renew: false)
    end

    before do
      login_as_user(member)
    end

    it "shows subscription as INACTIVE" do
      # Navigate to subscriptions page
      find('.user-profile').trigger("click")
      find('[data-testid="subscriptions-payment-btn"]').click

      # Should see subscription with INACTIVE status
      within("#my-subscriptions") do
        expect(page).to have_content(product.title)
        expect(page).to have_content("INACTIVE")
      end
    end
  end

  context "when member has no subscription" do
    before do
      login_as_user(member)
    end

    it "shows no subscriptions available message" do
      # Navigate to subscriptions page
      find('.user-profile').trigger("click")
      find('[data-testid="subscriptions-payment-btn"]').click

      # Should see no subscriptions message
      expect(page).to have_content("No subscriptions available")
    end
  end

  context "subscription date display" do
    let!(:order) { create(:order, member: member, state: :paid) }
    let!(:order_item) { create(:order_item, order: order, product: product) }

    before do
      login_as_user(member)
    end

    it "displays subscription duration correctly" do
      # Create subscription with specific dates
      create(:subscription,
        member: member,
        order: order,
        start_date: Date.new(2025, 1, 1),
        end_date: Date.new(2025, 1, 31),
        auto_renew: true)

      # Navigate to subscriptions page
      visit account_subscriptions_path

      # Should see formatted date range
      within("#my-subscriptions") do
        expect(page).to have_content("1-31 Jan 2025")
      end
    end
  end
end
