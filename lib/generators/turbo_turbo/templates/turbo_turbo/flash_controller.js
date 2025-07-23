import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-turbo--flash"
export default class extends Controller {
  connect() {
    setTimeout(() => this.fadeOut(this.element), (5000))
  }

  fadeOut(element){
    var intervalID = setInterval(() => {
      if (!element.style.opacity) {
        element.style.opacity = 1;
      }

      if (element.style.opacity > 0) {
        element.style.opacity -= 0.05;
      } else {
        clearInterval(intervalID);
        element.classList.add("hidden")
      }
    }, 75);
  }

  dismiss(){
    event.preventDefault();
    this.element.classList.add("hidden");
  }
}
