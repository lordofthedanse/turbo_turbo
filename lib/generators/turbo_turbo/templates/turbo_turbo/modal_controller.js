import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-turbo--modal"
export default class extends Controller {
  static targets = [ "background", "modalBackdrop", "title", "subtitle", "body", "modal", "footer", "form", "submitButton", "cancelButton" ]

  connect() {
    this.modalTarget.addEventListener('click', this.stopClickPropagation);
  }

  appendSubmitAndCancelButtons() {
    if (this.hasSubmitButtonTarget) {
      return;
    }
    this.footerTarget.appendChild(this.generateSubmitButton(this.dataset?.submitText || "Submit"));
    this.footerTarget.prepend(this.generateCancelButton(this.dataset?.cancelText || "Cancel"));
  }

  submitForm() {
    this.formTarget.requestSubmit();
  }

  disconnect() {
    this.modalTarget.removeEventListener('click', this.stopClickPropagation);
  }

  stopClickPropagation(event) {
    event.stopPropagation();
  }

  closeOnSuccess(){
    if (event.detail.success)
      this.closeModal()
  }

  async setRemoteSource() {
    event.preventDefault()
    const url = event.currentTarget.dataset.url;
    const title = event.currentTarget.dataset.title
    const subtitle = event.currentTarget.dataset.subtitle || ""
    const response = await fetch(url, {
      headers: { "Accept": "text/vnd.turbo-stream.html" }
    });

    const text = await response.text();
    const parser = new DOMParser();
    const doc = parser.parseFromString(text, "text/html");
    const stream = doc.querySelector("turbo-stream");
    if (title) {
      this.titleTarget.innerText = title;
    } else {
      document.getElementById("modal_title_bar_turbo_turbo").classList.add("hidden")
    }
    this.subtitleTarget.innerText = subtitle;
    this.bodyTarget.innerHTML = stream.querySelector("template").innerHTML;
    if (this.hasFormTarget) {
      this.appendSubmitAndCancelButtons();
    }
  }

  open() {
    this.backgroundTarget.classList.add("show");
    document.getElementById("modal_title_bar_turbo_turbo").classList.remove("hidden")
    this.backgroundTarget.addEventListener('transitionend', () => {
       this.modalBackdropTarget.classList.add("show");
    }, { once: true });
    document.body.classList.add("overflow-hidden")
  }

  close() {
    if (!event.target.closest('.Modal-turbo-turbo')) {
      this.closeModal()
    }
  }

  closeModal(){
    event.preventDefault()
    document.body.classList.remove("overflow-hidden")
    this.modalBackdropTarget.classList.remove("show");
    this.modalBackdropTarget.addEventListener('transitionend', () => {
      this.backgroundTarget.classList.remove("show");
      this.titleTarget.innerText = "";
      this.subtitleTarget.innerText = "";
      this.bodyTarget.innerHTML = "";
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.remove();
      }
      if (this.hasCancelButtonTarget) {
        this.cancelButtonTarget.remove();
      }
    }, { once: true });
  }

  generateCancelButton(cancelText){
    const button = document.createElement("button");
    button.classList.add("font-semibold", "leading-6", "text-gray-900");
    button.setAttribute("data-action", "turbo-turbo--modal#closeModal");
    button.setAttribute("data-turbo-turbo--modal-target", "cancelButton");
    button.textContent = cancelText

    return button
  }

  generateSubmitButton(submitText){
    const button = document.createElement("button");
    button.classList.add("rounded-md", "bg-primary-600", "px-3", "py-2", "text-sm", "font-semibold", "text-white", "shadow-sm", "hover:bg-primary-500", "focus-visible:outline", "focus-visible:outline-2", "focus-visible:outline-offset-2", "focus-visible:outline-primary-600");
    button.setAttribute("data-action", "turbo-turbo--modal#submitForm");
    button.setAttribute("data-turbo-turbo--modal-target", "submitButton");
    button.textContent = submitText

    return button
  }
}

