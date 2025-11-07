require 'rails_helper'

RSpec.describe "Admin::Customers", type: :request do
  let!(:member) { create(:member, first_name: "firstname", last_name: "lastname") }
  let!(:admin) { create(:admin_user) }
  before { sign_in admin }
  describe "GET /index" do
    it "returns http success" do
      get admin_customers_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get admin_customer_path(member)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get edit_admin_customer_path(member)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /update" do
    it "updates and redirects" do
      put admin_customer_path(member), params: {
        member: {
          id: member.id,
          first_name: "Pom",
          last_name: "Updated"
        }
      }
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /subscriptions/new" do
    it "returns http success" do
      get new_admin_customer_subscription_path(member)
      expect(response).to have_http_status(:success)
    end
  end
end
