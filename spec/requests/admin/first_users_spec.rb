require 'rails_helper'

RSpec.describe "Admin::FirstUsers", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/admin/first_users/new"
      expect(response).to have_http_status(:success)
    end
  end
end
