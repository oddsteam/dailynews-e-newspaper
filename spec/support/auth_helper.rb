module AuthHelper
  def login_as_user(user = nil)
    user = user || create(:member)

    # user clicks on the avatar icon to sign in
    visit root_path
    find('[data-testid="user-avatar"]', wait: 5).click

    # Wait for modal to open and switch to login form
    within('[data-testid="auth-modal"]', wait: 5) do
      find('[data-testid="switch-to-login"]').click

      # Wait for login form to load
      expect(page).to have_selector('[data-testid="login-form"]', wait: 5)

      # user fills in email and password, and sign in
      fill_in 'email', with: user.email
      fill_in 'password', with: 'password123'
      find('[data-testid="login-submit"]').click
    end

    # Wait for and verify successful login
    expect(page).to have_content('เข้าสู่ระบบเรียบร้อยแล้ว', wait: 5)

    user
  end

  def login_as_admin(admin = nil)
    admin = admin || create(:admin_user)

    visit admin_root_path

    # user fills in email and password, and sign in
    fill_in 'email', with: admin.email
    fill_in 'password', with: 'password123'
    find('[data-testid="admin-login-submit"]').click

    # Wait for and verify successful login
    expect(page).to have_content('เข้าสู่ระบบเรียบร้อยแล้ว', wait: 5)

    admin
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :system
end
