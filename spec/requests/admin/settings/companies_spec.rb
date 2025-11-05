require 'rails_helper'

RSpec.describe "Admin::Settings::Companies", type: :request do
  let!(:admin) { create(:admin_user) }
  before { sign_in admin }

  describe "GET /show" do
    it "returns http success" do
      get "/admin/settings/company"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /update" do
    it "returns http success" do
      put "/admin/settings/company", params: {
        company: {
          id: 1,
          name: "Test Co.",
          address_1: "address1",
          address_2: "address2",
          sub_district: "subdistrict",
          district: "district",
          province: "province",
          postal_code: "123456",
          country: "country",
          phone_number: "1234567890",
          email: "email@hotmail.com",
          logo: ""
        }
      }
      expect(response).to have_http_status(:found)
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    it "returns http success" do
      patch "/admin/settings/company", params: {
        company: {
          id: 1,
          name: "Test Co.",
          address_1: "address1",
          address_2: "address2",
          sub_district: "subdistrict",
          district: "district",
          province: "province",
          postal_code: "123456",
          country: "country",
          phone_number: "1234567890",
          email: "email@hotmail.com",
          logo: ""
        }
      }
      expect(response).to have_http_status(:found)
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end
end
