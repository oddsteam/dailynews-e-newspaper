require 'rails_helper'

describe "Terms and Conditions Modal", type: :system, js: true do
  include OmiseHelpers

  let!(:product) { create(:monthly_subscription_product) }

  before do
    visit root_path
    click_link_or_button "subscribe"
  end

  describe "Modal functionality" do
    it "opens when clicking the terms link" do
      expect(page).not_to have_selector("#my_modal[open]")

      click_link "เงื่อนไขการใช้บริการ"

      expect(page).to have_selector("#my_modal[open]")
      expect(page).to have_content("ข้อกำหนดและเงื่อนไขการให้บริการ")
    end

    it "closes when clicking the close button" do
      click_link "เงื่อนไขการใช้บริการ"
      expect(page).to have_selector("#my_modal[open]")

      within "#my_modal" do
        find('button[aria-label="Close"]').click
      end

      expect(page).not_to have_selector("#my_modal[open]")
    end

    it "displays all section headings" do
      click_link "เงื่อนไขการใช้บริการ"

      within "#my_modal" do
        expect(page).to have_content("1. บทนำ")
        expect(page).to have_content("2. การสมัครสมาชิกและการชำระค่าบริการ")
        expect(page).to have_content("3. เงื่อนไขการให้บริการ")
        expect(page).to have_content("4. ข้อตกลงการใช้บริการ")
        expect(page).to have_content("5. การแก้ไขข้อกำหนดและเงื่อนไข")
        expect(page).to have_content("6. ข้อสงวนสิทธิ์")
      end
    end
  end

  describe "Responsive design" do
    it "displays properly on mobile viewport" do
      page.current_window.resize_to(375, 667) # iPhone SE size

      click_link "เงื่อนไขการใช้บริการ"

      within "#my_modal" do
        expect(page).to have_content("ข้อกำหนดและเงื่อนไขการให้บริการ")
      end
    end

    it "displays properly on desktop viewport" do
      page.current_window.resize_to(1920, 1080)

      click_link "เงื่อนไขการใช้บริการ"

      within "#my_modal" do
        expect(page).to have_content("ข้อกำหนดและเงื่อนไขการให้บริการ")
      end
    end
  end

  describe "Integration with checkout flow" do
    it "allows user to read terms without interrupting checkout" do
      expect(page).to have_button("ดำเนินการต่อ", disabled: true)

      click_link "เงื่อนไขการใช้บริการ"
      within "#my_modal" do
        find('button[aria-label="Close"]').click
      end

      expect(page).to have_unchecked_field(type: "checkbox")

      expect(page).to have_button("ดำเนินการต่อ", disabled: true)
    end

    it "does not auto-check the terms checkbox after viewing modal" do
      click_link "เงื่อนไขการใช้บริการ"

      within "#my_modal .prose" do
        expect(page).to have_content("บทนำ")
      end

      within "#my_modal" do
        find('button[aria-label="Close"]').click
      end

      expect(page).to have_unchecked_field(type: "checkbox")
    end
  end
end
