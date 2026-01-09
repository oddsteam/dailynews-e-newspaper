require 'rails_helper'

describe "User can authenticate", js: true do
  it "allows a user to register via home page" do
    visit root_path
    find('.user-avatar').trigger("click")

    fill_in 'email', with: "register1@gmail.com"
    fill_in 'password', with: 'password123'
    fill_in 'confirm_password', with: 'password123'
    click_link_or_button 'สร้างบัญชีผู้ใช้'

    expect(page).to have_content('Welcome! You have signed up successfully.')
  end

  it "allows a user to register via sign up page" do
    visit new_member_registration_path

    fill_in 'email', with: "register2@gmail.com"
    fill_in 'password', with: 'password123'
    fill_in 'confirm_password', with: 'password123'
    click_link_or_button 'สร้างบัญชีผู้ใช้'

    expect(page).to have_content('Welcome! You have signed up successfully.')
  end

  context "when user account exists" do
    before { @user = create(:user) }

    it "allows user to login via home page" do
      visit root_path
      find('.user-avatar').trigger("click")
      click_link 'เข้าสู่ระบบ'

      fill_in 'email', with: @user.email
      fill_in 'password', with: 'password123'
      click_link_or_button 'เข้าสู่ระบบ'

      expect(page).to have_content('Signed in successfully.')
    end

    it "allows user to login via sign in page" do
      visit new_member_session_path

      fill_in 'email', with: @user.email
      fill_in 'password', with: 'password123'
      click_button 'เข้าสู่ระบบ'

      expect(page).to have_content('Signed in successfully.')
    end

    it "can switch between registration and sign in forms" do
      visit root_path
      find('.user-avatar').trigger("click")
      click_link 'เข้าสู่ระบบ'

      click_link 'สร้างบัญชีผู้ใช้'

      expect(page).to have_content('สร้างบัญชีผู้ใช้')
    end

    it "can navigate to forgot password page" do
      visit root_path
      find('.user-avatar').trigger("click")
      click_link 'เข้าสู่ระบบ'

      click_link 'ลืมรหัสผ่าน'

      expect(page).to have_content('ลืมรหัสผ่าน')
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

      find('.user-avatar').trigger("click")
      expect(page).to have_content('Signed out successfully.')
    end
  end
end
