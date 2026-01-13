import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "menu"]

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
    // Use capture phase to catch clicks before they bubble
    document.addEventListener("click", this.handleClickOutside, true)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside, true)
  }

  handleClickOutside(event) {
    // If dropdown is open and click is outside the dropdown element
    if (
      this.toggleTarget.checked &&
      !this.element.contains(event.target)
    ) {
      this.toggleTarget.checked = false
    }
  }
}
