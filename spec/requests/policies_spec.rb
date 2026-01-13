require 'rails_helper'

RSpec.describe "Policies", type: :request do
  describe "GET /policies/:id" do
    context "when accessing terms of service page" do
      it "returns http success" do
        get policy_path("terms_of_service")
        expect(response).to have_http_status(:success)
      end

      it "renders the terms of service content" do
        get policy_path("terms_of_service")
        expect(response.body).to include("ข้อกำหนดการให้บริการ")
      end
    end

    context "when accessing privacy policy page" do
      it "returns http success" do
        get policy_path("privacy")
        expect(response).to have_http_status(:success)
      end

      it "renders the privacy policy content" do
        get policy_path("privacy")
        expect(response.body).to include("Privacy Policy")
      end
    end

    context "when accessing cookie policy page" do
      it "returns http success" do
        get policy_path("cookies")
        expect(response).to have_http_status(:success)
      end

      it "renders the cookie policy content" do
        get policy_path("cookies")
        expect(response.body).to include("Cookie Policy")
      end
    end

    context "when accessing invalid policy page" do
      it "returns 404 error for invalid policy" do
        get "/policies/invalid_page"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "allows access to terms of service without login" do
        get policy_path("terms_of_service")
        expect(response).to have_http_status(:success)
      end

      it "allows access to privacy policy without login" do
        get policy_path("privacy")
        expect(response).to have_http_status(:success)
      end

      it "allows access to cookie policy without login" do
        get policy_path("cookies")
        expect(response).to have_http_status(:success)
      end
    end
  end
end
