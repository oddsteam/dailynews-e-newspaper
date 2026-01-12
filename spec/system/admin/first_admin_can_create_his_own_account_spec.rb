require 'rails_helper'

describe "First admin can create his own account", js: true do
  it "creates a new admin user account" do
    visit admin_root_path

    expect(page).to have_content("Admin Sign Up")

    email = "newadmin#{Time.now.to_i}@example.com"
    fill_in 'email', with: email
    fill_in 'password', with: 'password123'
    fill_in 'confirm_password', with: 'password123'
    click_link_or_button 'SIGN UP'

    # Should see success message and be redirected to sign in
    expect(page).to have_content("คุณต้องเข้าสู่ระบบหรือสร้างบัญชีผู้ใช้ก่อนดำเนินการต่อ")
    expect(Admin::User.find_by(email: email)).to be_present
  end

  context "when admin user already exists" do
    before { @admin_user = create(:admin_user) }

    it "allows admin user to sign in" do
      visit admin_root_path

      expect(page).to have_content("Admin Sign In")
      expect(page).to have_content("คุณต้องเข้าสู่ระบบหรือสร้างบัญชีผู้ใช้ก่อนดำเนินการต่อ")

      fill_in 'email', with: @admin_user.email
      fill_in 'password', with: 'password123'
      click_link_or_button 'SIGN IN'

      expect(page).to have_content("เข้าสู่ระบบเรียบร้อยแล้ว")
    end
  end
end
