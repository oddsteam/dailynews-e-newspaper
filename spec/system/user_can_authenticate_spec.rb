require 'rails_helper'

describe "User can authenticate", js: true do
  it "allows a user to register via home page" do
    visit root_path
    find('[data-testid="login-btn"]').click
    expect(page).to have_selector('[data-testid="login-form"]', wait: 5)
    find('[data-testid="switch-to-signup"]').click

    fill_in 'email', with: "register1@gmail.com"
    fill_in 'password', with: 'password123'
    fill_in 'confirm_password', with: 'password123'
    find('[data-testid="signup-submit"]').click

    expect(page).to have_content('ยินดีต้อนรับ! คุณสมัครสมาชิกเรียบร้อยแล้ว')
  end

  it "allows a user to register via sign up page" do
    visit new_member_registration_path

    fill_in 'email', with: "register2@gmail.com"
    fill_in 'password', with: 'password123'
    fill_in 'confirm_password', with: 'password123'
    find('[data-testid="signup-submit"]').click

    expect(page).to have_content('ยินดีต้อนรับ! คุณสมัครสมาชิกเรียบร้อยแล้ว')
  end

  context "when user account exists" do
    before { @user = create(:user) }

    it "allows user to login via home page" do
      visit root_path
      find('[data-testid="login-btn"]').click
      expect(page).to have_selector('[data-testid="login-form"]', wait: 5)

      fill_in 'email', with: @user.email
      fill_in 'password', with: 'password123'
      find('[data-testid="login-submit"]').click

      expect(page).to have_content('เข้าสู่ระบบเรียบร้อยแล้ว')
    end

    it "allows user to login via sign in page" do
      visit new_member_session_path

      fill_in 'email', with: @user.email
      fill_in 'password', with: 'password123'
      find('[data-testid="login-submit"]').click

      expect(page).to have_content('เข้าสู่ระบบเรียบร้อยแล้ว')
    end

    it "can switch between sign in forms to registration form" do
      visit root_path
      find('[data-testid="login-btn"]').click
      expect(page).to have_selector('[data-testid="login-form"]', wait: 5)
      find('[data-testid="switch-to-signup"]').click
      expect(page).to have_selector('[data-testid="signup-form"]', wait: 5)
    end

    it "can navigate to forgot password page" do
      visit root_path
      find('[data-testid="login-btn"]').click
      expect(page).to have_selector('[data-testid="login-form"]', wait: 5)

      find('[data-testid="forgot-password-link"]').click

      expect(page).to have_selector('[data-testid="forgot-password-modal"]', wait: 5)
    end
  end

  context "when user is signed in" do
    before do
      @user = create(:user)
      login_as_user(@user)
    end

    it "allows user to sign out" do
      visit root_path

      find('.user-profile').trigger("click")
      click_link_or_button "ออกจากระบบ"

      find('[data-testid="login-btn"]').click
      expect(page).to have_content('ออกจากระบบเรียบร้อยแล้ว')
    end
  end
end
