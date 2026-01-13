require 'rails_helper'

describe "User can access Terms of Service page", js: true do
  it "allows user to view terms of service page" do
    visit policy_path("terms_of_service")

    expect(page).to have_content("ข้อกำหนดการให้บริการ")
    expect(page).to have_content("การยอมรับข้อกำหนด")
  end

  it "displays proper styling for markdown content" do
    visit policy_path("terms_of_service")

    expect(page).to have_css(".prose")
    expect(page).to have_css("h2")
  end

  it "is accessible without authentication" do
    visit policy_path("terms_of_service")

    expect(page).to have_http_status(200)
    expect(current_path).to eq(policy_path("terms_of_service"))
  end
end
