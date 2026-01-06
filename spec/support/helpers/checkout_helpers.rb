module CheckoutHelpers
  def accept_terms
    find('[data-testid="terms-checkbox"]', visible: :all).click
    expect(page).to have_checked_field('terms-checkbox')
  end
end
