import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "submitButton"]

  connect() {
    // Hide spinner on initial load
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
  }

  submit(event) {
    // Show the loading spinner
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }

    // Disable the submit button and change its text
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }

    // Scroll to top so user can see the loading spinner
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
