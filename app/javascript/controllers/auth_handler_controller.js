import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handlePendingSubscription()
  }

  handlePendingSubscription() {
    const pendingSku = sessionStorage.getItem('pendingSubscriptionSku')
    
    if (pendingSku && this.element.dataset.memberSignedIn === "true") {
      this.addToCartAndRedirect(pendingSku)
    }
  }

  async addToCartAndRedirect(sku) {
    try {
      const response = await fetch('/cart_items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ sku: sku })
      })
      
      sessionStorage.removeItem('pendingSubscriptionSku')
      
      if (response.redirected) {
        window.location.href = response.url
      } else if (response.ok) {
        window.location.href = '/checkout'
      }
    } catch (error) {
      console.error('Error adding to cart:', error)
      sessionStorage.removeItem('pendingSubscriptionSku')
    }
  }
}
