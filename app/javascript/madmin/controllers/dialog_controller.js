import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "frame"]

  connect() {
    // Close dialog when clicking the backdrop (outside the dialog box)
    this.dialogTarget.addEventListener("click", (event) => {
      if (event.target === this.dialogTarget) {
        this.dialogTarget.close()
      }
    })

    // When the turbo-frame can't find a matching frame in the redirect response
    // (i.e. a successful save redirected to the show page), close the dialog and
    // reload the page so the association table reflects the updated record.
    this.frameTarget.addEventListener("turbo:frame-missing", (event) => {
      event.preventDefault()
      this.dialogTarget.close()
      window.location.reload()
    })
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }
}
