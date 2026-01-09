require 'rails_helper'

describe "User profile management", js: true do
  before do
    login_as_user(member)
  end

  context "when member has complete profile" do
    let(:member) { create(:member, first_name: "John", last_name: "Doe") }

    it "displays all profile information" do
      # Navigate to account information page via dropdown
      find('.user-profile').trigger("click")
      click_link_or_button "จัดการบัญชี"

      # Should see account information page
      expect(page).to have_content("Information")
      expect(page).to have_content("Manage your account information")

      # Should see user information
      expect(page).to have_content(member.email)
      expect(page).to have_content("John")
      expect(page).to have_content("Doe")
      expect(page).to have_content("Member Since")
    end

    it "displays formatted member since date" do
      visit account_information_path

      # Should show formatted date
      formatted_date = member.created_at.strftime("%B %d, %Y")
      expect(page).to have_content(formatted_date)
    end

    it "can navigate to edit page with pre-filled values" do
      visit account_information_path

      # Click edit button
      click_link_or_button "Edit Information"

      # Should see edit page
      expect(page).to have_content("Edit Information")
      expect(page).to have_content("Update your account information")

      # Form should be pre-filled with current values
      expect(page).to have_field("Email", with: member.email)
      expect(page).to have_field("First Name", with: "John")
      expect(page).to have_field("Last Name", with: "Doe")
    end
  end

  context "when member has incomplete profile" do
    let(:member) { create(:member, first_name: nil, last_name: nil) }

    it "shows 'Not set' for missing first name and last name" do
      visit account_information_path

      # Should show "Not set" for missing fields
      expect(page).to have_content("Not set", count: 2)
    end
  end

  context "when updating with valid data" do
    let(:member) { create(:member, first_name: "John", last_name: "Doe") }

    it "updates email successfully" do
      visit edit_account_information_path

      # Update email
      fill_in "Email", with: "newemail@example.com"
      click_button "Save Changes"

      # Should see success message
      expect(page).to have_content("Account information updated successfully.")

      # Should be on show page with updated email
      expect(page).to have_content("newemail@example.com")

      # Verify email was updated in database
      member.reload
      expect(member.email).to eq("newemail@example.com")
    end

    it "updates first name and last name successfully" do
      visit edit_account_information_path

      # Update names
      fill_in "First Name", with: "Jane"
      fill_in "Last Name", with: "Smith"
      click_button "Save Changes"

      # Should see success message
      expect(page).to have_content("Account information updated successfully.")

      # Should be on show page with updated names
      expect(page).to have_content("Jane")
      expect(page).to have_content("Smith")

      # Verify names were updated in database
      member.reload
      expect(member.first_name).to eq("Jane")
      expect(member.last_name).to eq("Smith")
    end

    it "updates all fields at once" do
      visit edit_account_information_path

      # Update all fields
      fill_in "Email", with: "updated@example.com"
      fill_in "First Name", with: "Updated"
      fill_in "Last Name", with: "Name"
      click_button "Save Changes"

      # Should see success message
      expect(page).to have_content("Account information updated successfully.")

      # Verify all fields were updated
      member.reload
      expect(member.email).to eq("updated@example.com")
      expect(member.first_name).to eq("Updated")
      expect(member.last_name).to eq("Name")
    end

    it "persists changes after navigation" do
      visit edit_account_information_path

      # Update email
      fill_in "Email", with: "persistent@example.com"
      click_button "Save Changes"

      # Navigate away and come back
      visit root_path
      visit account_information_path

      # Changes should still be visible
      expect(page).to have_content("persistent@example.com")
    end

    it "allows clearing optional first name and last name fields" do
      visit edit_account_information_path

      # Clear name fields
      fill_in "First Name", with: ""
      fill_in "Last Name", with: ""
      click_button "Save Changes"

      # Should succeed (names are optional)
      expect(page).to have_content("Account information updated successfully.")

      # Verify names were cleared
      member.reload
      expect(member.first_name).to be_blank
      expect(member.last_name).to be_blank
    end

    it "cancels editing without saving changes" do
      visit edit_account_information_path

      original_email = member.email

      # Change email but cancel
      fill_in "Email", with: "cancelled@example.com"
      click_link "Cancel"

      # Should be back on show page
      expect(page).to have_content("Information")
      expect(page).to have_content("Manage your account information")

      # Original email should still be displayed
      expect(page).to have_content(original_email)

      # Verify email was NOT changed in database
      member.reload
      expect(member.email).to eq(original_email)
    end
  end

  context "when updating with invalid data" do
    let(:member) { create(:member, first_name: "John", last_name: "Doe") }

    it "rejects invalid email format" do
      visit edit_account_information_path

      # Enter invalid email
      fill_in "Email", with: "invalid-email"
      click_button "Save Changes"

      # Should stay on edit page with error
      expect(page).to have_content("Edit Information")

      # Verify email was NOT changed
      member.reload
      expect(member.email).not_to eq("invalid-email")
    end

    it "rejects blank email" do
      visit edit_account_information_path

      # Clear email field
      fill_in "Email", with: ""
      click_button "Save Changes"

      # Should stay on edit page
      expect(page).to have_content("Edit Information")

      # Verify email was NOT changed
      member.reload
      expect(member.email).to be_present
    end
  end
end
