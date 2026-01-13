require 'rails_helper'

describe "User can access Cookie Policy page", js: true do
  it "allows user to view cookie policy page" do
    visit policy_path("cookies")

    expect(page).to have_content("Cookie Policy")
  end

  it "displays proper styling for markdown content" do
    visit policy_path("cookies")

    expect(page).to have_css(".prose")
    expect(page).to have_css("h2")
  end

  it "is accessible without authentication" do
    visit policy_path("cookies")

    expect(page).to have_http_status(200)
    expect(current_path).to eq(policy_path("cookies"))
  end
end
