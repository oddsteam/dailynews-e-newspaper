require 'rails_helper'

describe "Library access", js: true do
  let(:member) { create(:member) }

  before do
    login_as_user(member)
  end

  context "when member has no subscription" do
    before do
      # Ensure member has no subscriptions
      member.subscriptions.destroy_all
    end

    it "shows subscription package information" do
      visit library_path

      expect(page).to have_selector('[data-testid="my-library-link"]', wait: 5)
      expect(page).to have_content("หนังสือพิมพ์เดลินิวส์ฉบับดิจิทัล")
      expect(page).to have_content("สมัครสมาชิก")
    end
  end

  context "when member has active subscription" do
    let!(:subscription) do
      create(:subscription,
        member: member,
        start_date: Date.today,
        end_date: Date.today + 30.days,
        auto_renew: true)
    end

    context "with published newspaper" do
      before do
        create(:newspaper,
          title: "Daily News Today",
          published_at: Date.today)
      end

      it "member can read newspaper" do
        visit library_path

        expect(page).to have_content("Daily News Today")

        click_link_or_button "View Details"
        expect(page).to have_css(".back-to-library")
      end

      it "member back to library page in newspaper flip book" do
        visit library_path

        click_link_or_button "View Details"
        find(".back-to-library").trigger("click")

        expect(page).to have_content("Daily News Today")
      end
    end

    context "with multiple newspapers in subscription period" do
      before do
        # Create newspapers within subscription period
        create(:newspaper,
          title: "Daily News Today",
          published_at: Date.today)
        create(:newspaper,
          title: "Daily News Tomorrow",
          published_at: Date.today + 1.day)
      end

      it "shows newspapers within subscription period" do
        visit library_path

        # Should see newspapers
        expect(page).to have_content("Daily News Today")
        expect(page).to have_content("Daily News Tomorrow")
        expect(page).not_to have_content("No newspapers available")
      end
    end

    context "with newspapers in and out of subscription period" do
      before do
        # Create newspaper before subscription starts
        create(:newspaper,
          title: "Old News",
          published_at: Date.today - 10.days)

        # Create newspaper after subscription ends
        create(:newspaper,
          title: "Future News",
          published_at: Date.today + 60.days)

        # Create newspaper within subscription
        create(:newspaper,
          title: "Current News",
          published_at: Date.today + 5.days)
      end

      it "does not show newspapers outside subscription period" do
        visit library_path

        # Should only see newspaper within subscription
        expect(page).to have_content("Current News")
        expect(page).not_to have_content("Old News")
        expect(page).not_to have_content("Future News")
      end
    end
  end

  context "when member has expired subscription" do
    let!(:subscription) do
      create(:subscription,
        member: member,
        start_date: 2.months.ago,
        end_date: 1.month.ago,
        auto_renew: false)
    end

    context "with only newspaper from subscription period" do
      before do
        # Create newspaper within the old subscription period
        create(:newspaper,
          title: "Old Subscription News",
          published_at: 6.weeks.ago)
      end

      it "can still access newspapers from expired subscription period" do
        visit library_path

        # Should still see newspapers from expired period
        expect(page).to have_content("Old Subscription News")
        expect(page).not_to have_content("No newspapers available")
      end
    end

    context "with newspapers from both periods" do
      before do
        # Create newspaper within the old subscription period
        create(:newspaper,
          title: "Old Subscription News",
          published_at: 6.weeks.ago)

        # Create newspaper from today (outside expired subscription)
        create(:newspaper,
          title: "Today's News",
          published_at: Date.today)
      end

      it "does not show newspapers outside expired subscription period" do
        visit library_path

        # Should only see newspaper from expired period
        expect(page).to have_content("Old Subscription News")
        expect(page).not_to have_content("Today's News")
      end
    end
  end

  context "when member has continuous subscription" do
    let!(:subscription) do
      create(:subscription,
        member: member,
        start_date: Date.new(2025, 7, 1),
        end_date: Date.new(2025, 10, 31))
    end

    before do
      # Create newspapers at different times in subscription
      create(:newspaper,
        title: "July News",
        published_at: Date.new(2025, 7, 15))

      create(:newspaper,
        title: "October News",
        published_at: Date.new(2025, 10, 15))

      # Create newspaper before subscription
      create(:newspaper,
        title: "June News",
        published_at: Date.new(2025, 6, 15))

      # Create newspaper after subscription
      create(:newspaper,
        title: "November News",
        published_at: Date.new(2025, 11, 15))
    end

    it "shows newspapers throughout subscription period" do
      visit library_path

      # Should see newspapers within subscription period
      expect(page).to have_content("July News")
      expect(page).to have_content("October News")

      # Should NOT see newspapers outside subscription period
      expect(page).not_to have_content("June News")
      expect(page).not_to have_content("November News")
    end
  end

  context "when subscription spans multiple months with newspapers in each" do
    let!(:subscription) do
      create(:subscription,
        member: member,
        start_date: Date.new(2025, 1, 1),
        end_date: Date.new(2025, 3, 31))
    end

    before do
      # Create newspapers in different months
      create(:newspaper,
        title: "January News",
        published_at: Date.new(2025, 1, 15))
      create(:newspaper,
        title: "February News",
        published_at: Date.new(2025, 2, 15))
      create(:newspaper,
        title: "March News",
        published_at: Date.new(2025, 3, 15))
    end

    it "shows all newspapers when no month filter is selected" do
      visit library_path

      expect(page).to have_content("January News")
      expect(page).to have_content("February News")
      expect(page).to have_content("March News")
    end

    it "filters newspapers by selected month" do
      visit library_path

      # Select February from dropdown
      select "February", from: "month"

      # Should only see February newspaper
      expect(page).to have_content("February News")
      expect(page).not_to have_content("January News")
      expect(page).not_to have_content("March News")
    end
  end
end
