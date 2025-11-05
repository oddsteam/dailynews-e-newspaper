require 'rails_helper'

RSpec.describe "Members::Sessions", type: :request do
  let(:member) { create(:member) }

  describe "GET /members/sign_in" do
    it "renders the sign in page" do
      get "/members/sign_in"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /members/sign_in" do
    context "with valid password" do
      it "signs in the member and redirects to root path" do
        post member_session_path, params: { member: { email: member.email, password: member.password } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid password" do
      it "re-renders the sign in page with error" do
        post member_session_path, params: { member: { email: member.email, password: "wrongpassword" } }
        expect(response.body).to include("Invalid Email or password")
      end
    end
  end

  describe "DELETE /members/sign_out" do
    it "signs out a member" do
      sign_in member
      delete destroy_member_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
