module AuthHelper
  def login_as_user(user = nil)
    user = user || create(:member)

    # user clicks on the avatar icon to sign in
    visit root_path
    find('.user-avatar', wait: 5).trigger("click")
    click_link 'เข้าสู่ระบบ'

    # user fills in email and password, and sign in
    fill_in 'email', with: user.email
    fill_in 'password', with: 'password123'
    click_link_or_button 'เข้าสู่ระบบ'

    # Wait for and verify successful login
    expect(page).to have_content('Signed in successfully.', wait: 5)

    user
  end

  def login_as_admin(admin = nil)
    admin = admin || create(:admin_user)

    visit admin_root_path

    # user fills in email and password, and sign in
    fill_in 'email', with: admin.email
    fill_in 'password', with: 'password123'
    click_link_or_button 'SIGN IN'

    # Wait for and verify successful login
    expect(page).to have_content('Signed in successfully.', wait: 5)

    admin
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :system
end
