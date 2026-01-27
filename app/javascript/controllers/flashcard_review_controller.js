import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "item", "count"]

  connect() {
    console.log('Flashcard Review Controller Connected')
    console.log('Checkboxes found:', this.checkboxTargets.length)
    console.log('Items found:', this.itemTargets.length)
    console.log('Count target found:', this.hasCountTarget)
    
    this.updateSelectedCount()
    this.updateVisualState()
  }

  selectAll(event) {
    event.preventDefault()
    console.log('Select All clicked')
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
    this.updateSelectedCount()
    this.updateVisualState()
  }

  deselectAll(event) {
    event.preventDefault()
    console.log('Deselect All clicked')
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateSelectedCount()
    this.updateVisualState()
  }

  toggleSelection() {
    this.updateSelectedCount()
    this.updateVisualState()
  }

  updateSelectedCount() {
    const count = this.checkboxTargets.filter(cb => cb.checked).length
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
    }
  }

  updateVisualState() {
    this.itemTargets.forEach((item, index) => {
      const checkbox = this.checkboxTargets[index]
      if (checkbox && checkbox.checked) {
        item.classList.add('border-indigo-500', 'bg-indigo-50')
        item.classList.remove('border-transparent')
      } else {
        item.classList.remove('border-indigo-500', 'bg-indigo-50')
        item.classList.add('border-transparent')
      }
    })
  }
}
