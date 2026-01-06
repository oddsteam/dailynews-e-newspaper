require 'rails_helper'

describe "User can checkout", js: true do
  include OmiseHelpers

  let!(:product) { create(:monthly_subscription_product) }

  it "completes full purchase journey from guest to subscribed member" do
    # Guest visits home page
    visit root_path

    # Guest clicks subscribe button
    click_link_or_button "subscribe"
    expect(page).not_to have_content "subscribe"

    # Guest continues to payment and is prompted to sign up
    click_link_or_button "ดำเนินการต่อ"

    # Guest fills in signup form
    fill_in 'email', with: "newguest@example.com"
    fill_in 'password', with: 'password123'
    fill_in 'confirm_password', with: 'password123'
    click_link_or_button 'SIGN UP'

    # Guest completes payment with credit card
    user_pays_with_omise(token: 'tokn_test_5mokdpoelz84n3ai99l')

    # Should be redirected to success page after payment
    expect(page).to have_content "Thank You for Your Purchase"

    # Verify subscription was created - navigate to subscription page
    find('.user-profile').trigger("click")
    click_link_or_button "Subscriptions & Payments"
    expect(page).to have_content "Subscription Details"

    # Verify subscription is active
    within("#my-subscriptions") do
      expect(page).to have_content("ACTIVE")
      expect(page).to have_content("Renews on")
    end
  end

  it "shows product details during checkout" do
    # Guest visits home page and adds product to cart
    visit root_path
    click_link_or_button "subscribe"

    # Should see product details on checkout page
    expect(page).to have_content("Order Summary")
    expect(page).to have_content(product.title)

    # Should see tax breakdown
    expect(page).to have_content("Subtotal")
    expect(page).to have_content("VAT (7%)")
    expect(page).to have_content("Total")
  end

  it "requires authentication before payment" do
    # Guest visits home page and adds product to cart
    visit root_path
    click_link_or_button "subscribe"

    # Should be on checkout page
    expect(page).to have_current_path(checkout_path)

    # Click ดำเนินการต่อ should show auth modal, not process payment
    click_link_or_button "ดำเนินการต่อ"

    # Should see signup form
    expect(page).to have_content("Sign Up")
    expect(page).to have_field('email')
    expect(page).to have_field('password')
    expect(page).to have_field('confirm_password')
  end

  it "redirects to root when accessing checkout without adding product" do
    # Visit home page as guest
    visit root_path

    # Open checkout with url path
    visit checkout_path

    # Should stay on root path
    expect(page).to have_current_path(root_path)
  end

  it "allows access to checkout after clicking subscribe button" do
    # Visit home page as guest
    visit root_path

    # Click subscribe button
    click_button "subscribe"

    # Back to home page as guest
    visit root_path

    # Open checkout with url path
    visit checkout_path

    # Should stay on checkout path
    expect(page).to have_current_path(checkout_path)

    # Checkout page should be visible
    expect(page).to have_content("Order Summary")
  end

  it "can add product to cart and reach checkout page" do
    # Visit home page as guest
    visit root_path

    # Click subscribe button
    click_button "subscribe"

    # Should show success message
    expect(page).to have_content("Product added to cart")

    # Should be redirected to checkout page
    expect(page).to have_current_path(checkout_path)

    # Checkout page should be visible
    expect(page).to have_content("Order Summary")
  end

  it "sees authentication modal when clicking payment button" do
    # Visit home page and add product to cart
    visit root_path
    click_button "subscribe"

    # Should be on checkout page
    expect(page).to have_current_path(checkout_path)

    # Click ดำเนินการต่อ
    click_link_or_button "ดำเนินการต่อ"

    # Should see auth modal (not payment processing)
    expect(page).to have_content("Sign Up")
    expect(page).to have_field('email')
    expect(page).to have_field('password')
  end

  it "sees product information on checkout page" do
    # Visit home page and add product to cart
    visit root_path
    click_button "subscribe"

    # Should see product details
    expect(page).to have_content(product.title)
    expect(page).to have_content("Order Summary")

    # Should see selected plan section
    expect(page).to have_content("Selected Plan")
  end

  it "sees tax breakdown on checkout page" do
    # Visit home page and add product to cart
    visit root_path
    click_button "subscribe"

    # Should see tax information
    expect(page).to have_content("Subtotal")
    expect(page).to have_content("VAT (7%)")
    expect(page).to have_content("Total")
  end

  context "when member is signed in without subscription" do
    let(:member) { create(:member) }

    before do
      login_as_user(member)
    end

    it "redirects to root when accessing checkout without adding product" do
      # Visit home page
      visit root_path

      # Open checkout with url path
      visit checkout_path

      # Should stay on root path
      expect(page).to have_current_path(root_path)
    end

    it "can add product to cart and reach checkout page" do
      # Visit home page
      visit root_path

      # Click subscribe button
      click_button "subscribe"

      # Should show success message
      expect(page).to have_content("Product added to cart")

      # Should be redirected to checkout page
      expect(page).to have_current_path(checkout_path)

      # Checkout page should be visible
      expect(page).to have_content("Order Summary")
    end

    it "sees payment button instead of auth modal" do
      # Visit home page and add product to cart
      visit root_path
      click_button "subscribe"

      # Should be on checkout page
      expect(page).to have_current_path(checkout_path)

      # Should see ดำเนินการต่อ button
      expect(page).to have_button("ดำเนินการต่อ")

      # Should NOT trigger auth modal (member already logged in)
      # The button should be set up to trigger Omise payment
    end

    it "sees product information on checkout page" do
      # Visit home page and add product to cart
      visit root_path
      click_button "subscribe"

      # Should see product details
      expect(page).to have_content(product.title)
      expect(page).to have_content("Order Summary")

      # Should see selected plan section
      expect(page).to have_content("Selected Plan")
    end

    it "can access checkout page directly if cart exists" do
      # Add product to cart first
      visit root_path
      click_button "subscribe"

      # Leave checkout page
      visit root_path

      # Can access checkout directly
      visit checkout_path
      expect(page).to have_current_path(checkout_path)
      expect(page).to have_content("Order Summary")
      expect(page).to have_content(product.title)
    end
  end

  context "when member has active subscription" do
    let(:member_with_subscription) { create(:member) }
    let!(:subscription) { create(:subscription, member: member_with_subscription) }

    before do
      login_as_user(member_with_subscription)
    end

    it "redirects to library when accessing checkout" do
      # Visit home page
      visit root_path

      # Open checkout with url path
      visit checkout_path

      # Should redirect to library
      expect(page).to have_current_path(library_path)
    end
  end

  context "when existing member account exists" do
    let(:existing_member) { create(:member) }

    it "allows existing member to login from signup modal and complete purchase" do
      # Visit home page as guest (not logged in)
      visit root_path

      # Add product to cart
      click_button "subscribe"
      expect(page).to have_content("Product added to cart")

      # ดำเนินการต่อ, should show signup modal
      click_link_or_button "ดำเนินการต่อ"
      expect(page).to have_content("Sign Up")

      # Switch to login form
      click_link "Sign in here"
      expect(page).to have_content("Sign In")

      # Fill in existing member credentials
      fill_in 'email', with: existing_member.email
      fill_in 'password', with: 'password123'
      click_link_or_button 'SIGN IN'

      # Should be logged in successfully
      expect(page).to have_content('Signed in successfully.')

      # Continue with payment using Omise
      user_pays_with_omise(token: 'tokn_test_5mokdpoelz84n3ai99l')

      # Should be redirected to success page after payment
      expect(page).to have_content "Thank You for Your Purchase"

      # Verify subscription was created - navigate to subscription page
      find('.user-profile').trigger("click")
      click_link_or_button "Subscriptions & Payments"
      expect(page).to have_content "Subscription Details"

      # Verify subscription is active
      within("#my-subscriptions") do
        expect(page).to have_content("ACTIVE")
        expect(page).to have_content("Renews on")
      end
    end

    context "when member is signed in" do
      before do
        login_as_user(existing_member)
      end

      it "shows product details in checkout for logged-in member" do
        # Visit home page and add product to cart
        visit root_path
        click_button "subscribe"

        # Should be on checkout page
        expect(page).to have_current_path(checkout_path)

        # Should see product details
        expect(page).to have_content("Order Summary")
        expect(page).to have_content(product.title)

        # Should see tax breakdown
        expect(page).to have_content("Subtotal")
        expect(page).to have_content("VAT (7%)")
        expect(page).to have_content("Total")

        # Should see ดำเนินการต่อ button (not auth modal trigger)
        expect(page).to have_button("ดำเนินการต่อ")
      end
    end

    it "preserves cart after login" do
      # Visit home page as guest
      visit root_path

      # Add product to cart
      click_button "subscribe"
      expect(page).to have_content("Product added to cart")

      # Trigger auth modal
      click_link_or_button "ดำเนินการต่อ"

      # Switch to login and sign in
      click_link "Sign in here"
      fill_in 'email', with: existing_member.email
      fill_in 'password', with: 'password123'
      click_link_or_button 'SIGN IN'

      # Cart should still contain the product
      expect(page).to have_content(product.title)
      expect(page).to have_content("Order Summary")
    end
  end

  context "when member is signed in" do
    let(:existing_member) { create(:member) }

    before do
      login_as_user(existing_member)
    end

    context "when payment fails" do
      it "shows error message and keeps product in cart for retry" do
        # Add product to cart
        visit root_path
        click_button "subscribe"

        # Attempt payment but it fails
        user_pays_with_omise_but_fails

        # Should be redirected to checkout page with error
        expect(page).to have_current_path(checkout_path)
        expect(page).to have_content("Payment failed. Please try again.")

        # User can see the product in cart to retry
        expect(page).to have_content(product.title)
        expect(page).to have_content("Order Summary")
      end

      it "allows user to retry payment and succeed after initial failure" do
        # Add product to cart
        visit root_path
        click_button "subscribe"

        # First attempt - payment fails
        user_pays_with_omise_but_fails

        # Should be back on checkout page
        expect(page).to have_current_path(checkout_path)
        expect(page).to have_content("Payment failed. Please try again.")

        # Second attempt - payment succeeds
        user_pays_with_omise(token: 'tokn_test_5mokdpoelz84n3ai99l')

        # Should complete successfully
        expect(page).to have_content "Thank You for Your Purchase"

        # Verify subscription was created after retry
        find('.user-profile').trigger("click")
        click_link_or_button "Subscriptions & Payments"

        within("#my-subscriptions") do
          expect(page).to have_content("ACTIVE")
        end
      end
    end
  end

  describe "active subscription prevention" do
    let(:member) { create(:member) }

    context "when member has active subscription" do
      let!(:subscription) { create(:subscription, member: member, start_date: Date.today, end_date: Date.today + 1.month) }

      before do
        login_as_user(member)
      end

      it "shows 'Go to Library' button on home page instead of subscribe button" do
        visit root_path

        # Should show "Go to Library" button
        expect(page).to have_content(I18n.t("home.active_subscription_title"))
        expect(page).to have_content(I18n.t("home.active_subscription_message"))
        expect(page).to have_link(I18n.t("home.go_to_library"), href: library_path)

        # Should NOT show subscribe button
        expect(page).not_to have_button("subscribe")
      end

      it "redirects to library when trying to access checkout page" do
        visit checkout_path

        # Should redirect to library
        expect(page).to have_current_path(library_path)
        expect(page).to have_content("You already have an active subscription")
      end

      it "does not show subscribe button, preventing cart addition from UI" do
        visit root_path

        # The subscribe button should not be present, preventing cart addition
        expect(page).not_to have_button("subscribe")

        # The "Go to Library" link should be present instead
        expect(page).to have_link(I18n.t("home.go_to_library"), href: library_path)
      end
    end

    context "when member does not have active subscription" do
      before do
        login_as_user(member)
      end

      it "shows subscribe button on home page" do
        visit root_path

        # Should show subscribe button
        expect(page).to have_button("subscribe")

        # Should NOT show "Go to Library" message
        expect(page).not_to have_content(I18n.t("home.active_subscription_title"))
        expect(page).not_to have_link(I18n.t("home.go_to_library"))
      end

      it "can access checkout page" do
        # Add product to cart first
        visit root_path
        click_button "subscribe"
        expect(page).to have_content("Product added to cart")

        # Should be able to access checkout
        expect(page).to have_current_path(checkout_path)
        expect(page).to have_content("Order Summary")
      end
    end

    context "when member has expired subscription" do
      let!(:expired_subscription) { create(:subscription, member: member, start_date: 2.months.ago, end_date: 1.month.ago) }

      before do
        login_as_user(member)
      end

      it "shows subscribe button on home page" do
        visit root_path

        # Should show subscribe button (subscription is expired)
        expect(page).to have_button("subscribe")

        # Should NOT show "Go to Library" message
        expect(page).not_to have_content(I18n.t("home.active_subscription_title"))
      end

      it "can access checkout page" do
        # Add product to cart first
        visit root_path
        click_button "subscribe"
        expect(page).to have_content("Product added to cart")

        # Should be able to access checkout (subscription is expired)
        expect(page).to have_current_path(checkout_path)
        expect(page).to have_content("Order Summary")
      end
    end
  end
end
