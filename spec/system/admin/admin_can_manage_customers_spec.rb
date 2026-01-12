require 'rails_helper'

describe "Admin can manage customers", js: true do
  context "when admin is signed in and customers exist" do
    let!(:subscription) { create(:subscription) }
    let(:customer) { subscription.member }

    before do
      login_as_admin
    end

    it "navigates to customers page and displays customers" do
      click_link_or_button "Customers"

      expect(page).to have_current_path(admin_customers_path)
      expect(page).to have_content("Customers")
      expect(page).to have_content(customer.email)
    end

    it "navigates to customer information page" do
      click_link_or_button "Customers"
      find('.show-icon').trigger("click")

      expect(page).to have_current_path(admin_customer_path(customer))
      expect(page).to have_content("Purchase History")
    end
  end

  context "when admin is signed in and customer exists for editing" do
    before do
      @subscription = create(:subscription)
      login_as_admin
    end

    let(:customer) { @subscription.member }

    it "navigates to edit customer information page from list" do
      click_link_or_button "Customers"
      find('.edit-icon').trigger("click")

      expect(page).to have_current_path(edit_admin_customer_path(customer))
      expect(page).to have_content("Basic Information")
    end

    it "navigates to edit from customer information page" do
      click_link_or_button "Customers"
      find('.show-icon').trigger("click")
      click_link_or_button "Edit"

      expect(page).to have_current_path(edit_admin_customer_path(customer))
      expect(page).to have_content("Customer")
    end

    it "saves customer information without name changes" do
      click_link_or_button "Customers"
      find('.edit-icon').trigger("click")
      click_link_or_button "Save"

      expect(page).to have_current_path(admin_customer_path(customer))
      expect(page).to have_content("Purchase History")
      expect(page).to have_content("-")
    end

    it "saves customer information with name updates" do
      click_link_or_button "Customers"
      find('.edit-icon').trigger("click")
      fill_in 'member_first_name', with: "firstname"
      fill_in 'member_last_name', with: "lastname"
      click_link_or_button "Save"

      expect(page).to have_current_path(admin_customer_path(customer))
      expect(page).to have_content("Purchase History")
      expect(page).to have_content("firstname lastname")
    end

    it "navigates back from edit page when user clicks edit icon" do
      click_link_or_button "Customers"
      find('.edit-icon').trigger("click")
      fill_in 'member_first_name', with: "firstname"
      fill_in 'member_last_name', with: "lastname"
      click_link_or_button "Back"

      expect(page).to have_current_path(admin_customers_path)
      expect(page).to have_content("Customer")
    end

    it "cancels editing customer information when user clicks edit icon" do
      click_link_or_button "Customers"
      find('.edit-icon').trigger("click")
      fill_in 'member_first_name', with: "firstname"
      fill_in 'member_last_name', with: "lastname"
      click_link_or_button "Cancel"

      expect(page).to have_current_path(admin_customers_path)
      expect(page).to have_content("Customer")
    end

    it "navigates back from edit page when user clicks show icon and edit customer" do
      click_link_or_button "Customers"
      find('.show-icon').trigger("click")
      click_link_or_button "Edit"

      click_link_or_button "Back"

      expect(page).to have_current_path(admin_customer_path(customer))
    end
  end

  context "when admin is signed in and subscription exists" do
    before do
      @subscription = create(:subscription)
      login_as_admin
    end

    let(:customer) { @subscription.member }

    it "displays all subscriptions" do
      click_link_or_button "Subscriptions"

      expect(page).to have_current_path(admin_subscriptions_path)
      expect(page).to have_link("Subscriptions")
      expect(page).to have_content(@subscription.member.email)
    end

    it "navigates to customer information page when viewing customer from subscriptions" do
      click_link_or_button "Subscriptions"
      click_link_or_button "View Customer"

      expect(page).to have_current_path(admin_customer_path(@subscription.member))
      expect(page).to have_content("Basic Information")
    end

    it "navigates to create subscription page" do
      click_link_or_button "Customers"
      find('.show-icon').trigger("click")
      click_link_or_button "Create Subscription"

      expect(page).to have_current_path(new_admin_customer_subscription_path(customer))
      expect(page).to have_content("Subscription Details")
    end

    it "creates a subscription with valid dates" do
      expect {
        click_link_or_button "Customers"
        find('.show-icon').trigger("click")
        click_link_or_button "Create Subscription"
        find("[data-testid='start_date_picker']").set("2025-10-30")
        find("[data-testid='end_date_picker']").set("2025-11-30")
        click_link_or_button "Save"
      }.to change(Subscription, :count).from(1).to(2)

      expect(page).to have_current_path(admin_customer_path(customer))
      expect(page).to have_content("Basic Information")
    end

    it "creates a subscription without providing dates" do
      expect {
        click_link_or_button "Customers"
        find('.show-icon').trigger("click")
        click_link_or_button "Create Subscription"
        click_link_or_button "Save"
      }.to change(Subscription, :count).from(1).to(2)

      expect(page).to have_current_path(admin_customer_path(customer))
      expect(page).to have_content("Basic Information")
    end

    it "cancels creating a subscription" do
      expect {
        click_link_or_button "Customers"
        find('.show-icon').trigger("click")
        click_link_or_button "Create Subscription"
        click_link_or_button "Cancel"
      }.not_to change(Subscription, :count)

      expect(page).to have_current_path(admin_customer_path(customer))
      expect(page).to have_content("Basic Information")
    end

    it "shows validation errors with invalid dates" do
      expect {
        click_link_or_button "Customers"
        find('.show-icon').trigger("click")
        click_link_or_button "Create Subscription"
        find("[data-testid='start_date_picker']").set("yyyy-mm-dd")
        find("[data-testid='end_date_picker']").set("yyyy-mm-dd")
        click_link_or_button "Save"
      }.not_to change(Subscription, :count)

      expect(page).to have_current_path(new_admin_customer_subscription_path(customer))
      expect(page).to have_content("2 error prohibited this subscription from being saved:")
      expect(page).to have_content("Start date ไม่สามารถว่างได้")
      expect(page).to have_content("End date ไม่สามารถว่างได้")
    end
  end

  context "when admin is signed in and no subscriptions exist" do
    before do
      Subscription.delete_all
      login_as_admin
    end

    it "shows empty list when no subscriptions exist" do
      click_link_or_button "Subscriptions"

      expect(page).to have_current_path(admin_subscriptions_path)
      expect(page).to have_link("Subscriptions")
      expect(page).not_to have_selector("tbody tr")
    end
  end
end
