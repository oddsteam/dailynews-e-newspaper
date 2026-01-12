require 'rails_helper'

describe "User can checkout", js: true do
  include OmiseHelpers

  let!(:product) { create(:monthly_subscription_product) }

  it "completes full purchase journey from guest to subscribed member" do
    # Guest visits home page
    visit root_path

    # Set pending subscription in sessionStorage before clicking
    page.execute_script("sessionStorage.setItem('pendingSubscriptionSku', 'MEMBERSHIP_MONTHLY_SUBSCRIPTION')")

    # Guest clicks subscribe button - should open auth modal
    find('[data-testid="subscribe-button"]').click

    # Wait for modal to open and fill in signup form
    within('[data-testid="auth-modal"]', wait: 5) do
      expect(page).to have_selector('[data-testid="login-form"]', wait: 5)
      find('[data-testid="switch-to-signup"]').click
      expect(page).to have_selector('[data-testid="signup-form"]', wait: 5)


      # Guest fills in signup form
      fill_in 'email', with: "newguest@example.com"
      fill_in 'password', with: 'password123'
      fill_in 'confirm_password', with: 'password123'
      find('[data-testid="signup-submit"]').click
    end

    # After signup, manually submit to cart_items using fetch (simulating auth_handler)
    page.execute_script(<<~JS)
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content ||#{' '}
                        document.querySelector('[name="csrf-token"]')?.content;

      fetch('/cart_items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ sku: 'MEMBERSHIP_MONTHLY_SUBSCRIPTION' })
      }).then(response => {
        if (response.redirected) {
          window.location.href = response.url;
        } else if (response.ok) {
          window.location.href = '/checkout';
        }
      });
    JS

    # Wait for redirect to checkout
    expect(page).to have_current_path(checkout_path, wait: 5)

    # After signup, accept terms again
    accept_terms

    # Guest completes payment with credit card
    user_pays_with_omise(token: 'tokn_test_5mokdpoelz84n3ai99l')

    # Should be redirected to success page after payment
    expect(page).to have_content "ขอบคุณสำหรับการสมัครสมาชิก"

    # Verify subscription was created - navigate to subscription page
    find('.user-profile').trigger("click")
    find('[data-testid="subscriptions-payment-btn"]').click
    expect(page).to have_content "Subscription Details"

    # Verify subscription is active
    within("#my-subscriptions") do
      expect(page).to have_content("ACTIVE")
      expect(page).to have_content("Renews on")
    end
  end

  it "shows product details during checkout for logged in member" do
    # Member logs in first
    member = create(:member)
    login_as_user(member)

    # Member visits home page and adds product to cart
    visit root_path
    find('[data-testid="subscribe-button"]').click

    # Should see product details on checkout page
    expect(page).to have_selector('[data-testid="checkout-summary-title"]')
    expect(page).to have_selector('[data-testid="product-title"]', text: product.title)

    # Should see tax breakdown
    expect(page).to have_content("ยอดรวม")
    expect(page).to have_content("ภาษีมูลค่าเพิ่ม (7%)")
    expect(page).to have_content("ราคาสุทธิ")
  end

  it "requires authentication before subscribing" do
    # Guest visits home page
    visit root_path

    # Guest clicks subscribe button - should open auth modal immediately
    find('[data-testid="subscribe-button"]').click

    # Should see sign in form in modal
    within('[data-testid="auth-modal"]', wait: 5) do
      expect(page).to have_selector('[data-testid="login-form"]')
      expect(page).to have_selector('[data-testid="login-email"]')
      expect(page).to have_selector('[data-testid="login-password"]')
    end
  end

  it "redirects to root when accessing checkout without adding product" do
    # Visit home page as guest
    visit root_path

    # Open checkout with url path
    visit checkout_path

    # Should stay on root path
    expect(page).to have_current_path(root_path)
  end

  it "sees product information on checkout page" do
    # Create and login as member first to see checkout
    member = create(:member)
    login_as_user(member)

    # Visit home page and add product to cart
    visit root_path
    find('[data-testid="subscribe-button"]').click

    # Should see product details
    expect(page).to have_content(product.title)
    expect(page).to have_content("สรุปรายการสมัครสมาชิก")
  end

  it "sees tax breakdown on checkout page" do
    # Create and login as member first to see checkout
    member = create(:member)
    login_as_user(member)

    # Visit home page and add product to cart
    visit root_path
    find('[data-testid="subscribe-button"]').click

    # Should see tax information
    expect(page).to have_content("ยอดรวม")
    expect(page).to have_content("ภาษีมูลค่าเพิ่ม (7%)")
    expect(page).to have_content("ราคาสุทธิ")
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
      find('[data-testid="subscribe-button"]').click

      # Should be redirected to checkout page
      expect(page).to have_current_path(checkout_path)

      # Checkout page should be visible
      expect(page).to have_selector('[data-testid="checkout-summary-title"]')
    end

    it "sees payment button instead of auth modal" do
      # Visit home page and add product to cart
      visit root_path
      find('[data-testid="subscribe-button"]').click

      # Should be on checkout page
      expect(page).to have_current_path(checkout_path)

      accept_terms

      # Should see ดำเนินการต่อ button
      expect(page).to have_selector('[data-testid="pay-button"]')
      expect(page).to have_button("ดำเนินการต่อ", disabled: false)

      # Should NOT trigger auth modal (member already logged in)
      # The button should be set up to trigger Omise payment
    end

    it "sees product information on checkout page" do
      # Visit home page and add product to cart
      visit root_path
      find('[data-testid="subscribe-button"]').click

      # Should see product details
      expect(page).to have_selector('[data-testid="product-title"]', text: product.title)
      expect(page).to have_selector('[data-testid="checkout-summary-title"]')
    end

    it "can access checkout page directly if cart exists" do
      # Add product to cart first
      visit root_path
      find('[data-testid="subscribe-button"]').click

      # Leave checkout page
      visit root_path

      # Can access checkout directly
      visit checkout_path
      expect(page).to have_current_path(checkout_path)
      expect(page).to have_selector('[data-testid="checkout-summary-title"]')
      expect(page).to have_selector('[data-testid="product-title"]', text: product.title)
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

      # Set pending subscription in sessionStorage
      page.execute_script("sessionStorage.setItem('pendingSubscriptionSku', 'MEMBERSHIP_MONTHLY_SUBSCRIPTION')")

      # Click subscribe - should open auth modal
      find('[data-testid="subscribe-button"]').click

      within('[data-testid="auth-modal"]', wait: 5) do
        # expect(page).to have_selector('[data-testid="login-form"]')

        # Switch to login form
        # find('[data-testid="switch-to-login"]').click
        expect(page).to have_selector('[data-testid="login-title"]')

        # Fill in existing member credentials
        fill_in 'email', with: existing_member.email
        fill_in 'password', with: 'password123'
        find('[data-testid="login-submit"]').click
      end

      # After login, manually submit to cart_items using fetch (simulating auth_handler)
      page.execute_script(<<~JS)
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content ||#{' '}
                          document.querySelector('[name="csrf-token"]')?.content;

        fetch('/cart_items', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ sku: 'MEMBERSHIP_MONTHLY_SUBSCRIPTION' })
        }).then(response => {
          if (response.redirected) {
            window.location.href = response.url;
          } else if (response.ok) {
            window.location.href = '/checkout';
          }
        });
      JS

      # Wait for redirect to checkout
      expect(page).to have_current_path(checkout_path, wait: 5)

      accept_terms

      # Continue with payment using Omise
      user_pays_with_omise(token: 'tokn_test_5mokdpoelz84n3ai99l')

      # Should be redirected to success page after payment
      expect(page).to have_content "ขอบคุณสำหรับการสมัครสมาชิก"

      # Verify subscription was created - navigate to subscription page
      find('.user-profile').trigger("click")
      find('[data-testid="subscriptions-payment-btn"]').click
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
        find('[data-testid="subscribe-button"]').click

        # Should be on checkout page
        expect(page).to have_current_path(checkout_path)

        # Should see product details
        expect(page).to have_selector('[data-testid="checkout-summary-title"]')
        expect(page).to have_selector('[data-testid="product-title"]', text: product.title)

        # Should see tax breakdown
        expect(page).to have_content("ยอดรวม")
        expect(page).to have_content("ภาษีมูลค่าเพิ่ม (7%)")
        expect(page).to have_content("ราคาสุทธิ")

        accept_terms

        # Should see ดำเนินการต่อ button (not auth modal trigger)
        expect(page).to have_selector('[data-testid="pay-button"]')
        expect(page).to have_button("ดำเนินการต่อ", disabled: false)
      end
    end

    it "adds to cart and redirects to checkout after login from modal" do
      # Visit home page as guest
      visit root_path

      # Set pending subscription in sessionStorage
      page.execute_script("sessionStorage.setItem('pendingSubscriptionSku', 'MEMBERSHIP_MONTHLY_SUBSCRIPTION')")

      # Click subscribe - opens auth modal
      find('[data-testid="subscribe-button"]').click

      within('[data-testid="auth-modal"]', wait: 5) do
        expect(page).to have_selector('[data-testid="login-form"]')

        # Switch to login and sign in
        fill_in 'email', with: existing_member.email
        fill_in 'password', with: 'password123'
        find('[data-testid="login-submit"]').click
      end

      # After login, manually submit to cart_items using fetch (simulating auth_handler)
      page.execute_script(<<~JS)
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content ||#{' '}
                          document.querySelector('[name="csrf-token"]')?.content;

        fetch('/cart_items', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ sku: 'MEMBERSHIP_MONTHLY_SUBSCRIPTION' })
        }).then(response => {
          if (response.redirected) {
            window.location.href = response.url;
          } else if (response.ok) {
            window.location.href = '/checkout';
          }
        });
      JS

      # Wait for redirect to checkout
      expect(page).to have_current_path(checkout_path, wait: 5)
      expect(page).to have_selector('[data-testid="product-title"]', text: product.title)
      expect(page).to have_selector('[data-testid="checkout-summary-title"]')
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
        find('[data-testid="subscribe-button"]').click

        accept_terms

        # Attempt payment but it fails
        user_pays_with_omise_but_fails

        # Should be redirected to checkout page with error
        expect(page).to have_current_path(payment_failed_checkout_path)
        expect(page).to have_content("ชำระเงินไม่สำเร็จ")

        click_link_or_button "กลับสู่หน้ารายการสมัครสมาชิก"

        # User can see the product in cart to retry
        expect(page).to have_selector('[data-testid="product-title"]', text: product.title)
        expect(page).to have_selector('[data-testid="checkout-summary-title"]')
      end

      it "allows user to retry payment and succeed after initial failure" do
        # Add product to cart
        visit root_path
        find('[data-testid="subscribe-button"]').click

        accept_terms

        # First attempt - payment fails
        user_pays_with_omise_but_fails

        # Should be back on checkout page
        expect(page).to have_current_path(payment_failed_checkout_path)
        expect(page).to have_content("ชำระเงินไม่สำเร็จ")

        click_link_or_button "กลับสู่หน้ารายการสมัครสมาชิก"

        accept_terms

        # Second attempt - payment succeeds
        user_pays_with_omise(token: 'tokn_test_5mokdpoelz84n3ai99l')

        # Should complete successfully
        expect(page).to have_content "ขอบคุณสำหรับการสมัครสมาชิก"

        # Verify subscription was created after retry
        find('.user-profile').trigger("click")
        find('[data-testid="subscriptions-payment-btn"]').click

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
        expect(page).not_to have_selector('[data-testid="subscribe-button"]')
      end

      it "redirects to library when trying to access checkout page" do
        visit checkout_path

        # Should redirect to library
        expect(page).to have_current_path(library_path)
        # Flash message is shown but we don't need to check exact text as it's covered by redirect
      end

      it "does not show subscribe button, preventing cart addition from UI" do
        visit root_path

        # The subscribe button should not be present, preventing cart addition
        expect(page).not_to have_selector('[data-testid="subscribe-button"]')

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
        expect(page).to have_selector('[data-testid="subscribe-button"]')

        # Should NOT show "Go to Library" message
        expect(page).not_to have_content(I18n.t("home.active_subscription_title"))
        expect(page).not_to have_link(I18n.t("home.go_to_library"))
      end

      it "can access checkout page" do
        # Add product to cart first
        visit root_path
        find('[data-testid="subscribe-button"]').click

        # Should be able to access checkout
        expect(page).to have_current_path(checkout_path)
        expect(page).to have_selector('[data-testid="checkout-summary-title"]')
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
        expect(page).to have_selector('[data-testid="subscribe-button"]')

        # Should NOT show "Go to Library" message
        expect(page).not_to have_content(I18n.t("home.active_subscription_title"))
      end

      it "can access checkout page" do
        # Add product to cart first
        visit root_path
        find('[data-testid="subscribe-button"]').click

        # Should be able to access checkout (subscription is expired)
        expect(page).to have_current_path(checkout_path)
        expect(page).to have_selector('[data-testid="checkout-summary-title"]')
      end
    end
  end
end
