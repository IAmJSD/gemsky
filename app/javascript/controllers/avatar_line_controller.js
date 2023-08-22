import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="avatar-line"
export default class extends Controller {
  connect() {
    let elements = [...this.element.querySelectorAll("[data-line-target]")]

    // Get the pairs to connect.
    this. pairs = []
    let p = elements.pop()
    while (p) {
      // Get the last element.
      const last = elements.pop()
      if (last) {
        this.pairs.push([last, p])
      }
      p = last
    }

    // Get/watch the color scheme of the browser.
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.darkMode = this.mediaQuery.matches
    this.darkHandler = () => {
      this.darkMode = this.mediaQuery.matches
      this._destroySvg()
      this._createSvg()
    };
    this.mediaQuery.addEventListener("change", this.darkHandler)

    // Create the SVG.
    this._createSvg()

    // Recreate the lines when the window resizes.
    this.resizeHandler = () => {
      this._destroySvg()
      this._createSvg()
    }
    window.addEventListener("resize", this.resizeHandler)
    window.addEventListener("scroll", this.resizeHandler)

    // Hack to handle random fast DOM mutation.
    setTimeout(this.resizeHandler, 100)
  }

  disconnect() {
    this._destroySvg()
    this.mediaQuery.removeEventListener("change", this.darkHandler)
    window.removeEventListener("resize", this.resizeHandler)
    window.removeEventListener("scroll", this.resizeHandler)
  }

  _createSvg() {
    // Return if there are no pairs.
    if (this.pairs.length === 0) {
      return
    }

    // Make a absolute positioned SVG.
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")

    // Build the lines.
    for (const [top, bottom] of this.pairs) {
      // Get the absolute position of the bottom of the top.
      const topRect = top.getBoundingClientRect()
      const topX = topRect.left + topRect.width / 2
      const topY = topRect.top + topRect.height

      // Get the absolute position of the top of the bottom.
      const bottomRect = bottom.getBoundingClientRect()
      const bottomX = bottomRect.left + bottomRect.width / 2
      const bottomY = bottomRect.top

      // Create the line.
      const line = document.createElementNS("http://www.w3.org/2000/svg", "line")
      line.setAttribute("x1", `${topX}px`)
      line.setAttribute("y1", `${topY + 1 + window.pageYOffset}px`)
      line.setAttribute("x2", `${bottomX}px`)
      line.setAttribute("y2", `${bottomY + window.pageYOffset}px`)
      line.setAttribute("stroke", this.darkMode ? "#C8CCCC" : "#000")
      line.setAttribute("stroke-width", "2")
      line.setAttribute("stroke-linecap", "round")
      svg.appendChild(line)
    }

    // Make the overflow visible.
    svg.setAttribute("overflow", "visible")

    // Make a dom wrapper.
    const wrapper = document.createElement("div")
    wrapper.style.position = "absolute"
    wrapper.style.top = "0"
    wrapper.style.left = "0"
    wrapper.style.overflow = "show"
    wrapper.style.pointerEvents = "none"
    wrapper.appendChild(svg)

    // Add the SVG to the page.
    document.body.appendChild(wrapper)
    this.svg = wrapper
  }

  _destroySvg() {
    if (this.svg) {
      this.svg.remove()
      delete this.svg
    }
  }
}
