import { Controller } from "@hotwired/stimulus"

const timeout = ms => new Promise(r => setTimeout(r, ms))

// Connects to data-controller="avatar-line"
export default class extends Controller {
  connect() {
    let elements = [...this.element.querySelectorAll("[data-line-target]")]

    // Get the pairs to connect.
    this.pairs = []
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
      this._destroyLines()
      this._createLines()
    };
    this.mediaQuery.addEventListener("change", this.darkHandler)

    // Create the SVG.
    this._createLines()

    // Recreate the lines when the window resizes.
    this.resizeHandler = () => {
      this._destroyLines()
      this._createLines()
    }
    window.addEventListener("resize", this.resizeHandler)
    window.addEventListener("scroll", this.resizeHandler)

    // Hack to handle random fast DOM mutation.
    this._brutalDomShiftHack()

    // Handle mutations.
    this.observer = new MutationObserver(() => {
      this._destroyLines()
      this._createLines()
    })
    this.observer.observe(document.body)
  }

  disconnect() {
    this._destroyLines()
    this.mediaQuery.removeEventListener("change", this.darkHandler)
    window.removeEventListener("resize", this.resizeHandler)
    window.removeEventListener("scroll", this.resizeHandler)
    this.observer.disconnect()
  }

  _createLines() {
    // Return if there are no pairs.
    if (this.pairs.length === 0) {
      return
    }

    // Get the SVG.
    const svg = this.getWrappedSvg()

    // Build the lines.
    this.lines = []
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

      // Save the line.
      this.lines.push(line)
    }
  }

  _destroyLines() {
    if (!this.lines) return
    for (const line of this.lines) {
      line.remove()
    }
    this.lines = []
  }

  getWrappedSvg() {
    // Try to get _wrapped_svg from the DOM.
    let svg = document.getElementById("_wrapped_svg")
    if (svg) return svg

    // Make a SVG.
    svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.id = "_wrapped_svg"

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
    return svg
  }

  async _brutalDomShiftHack() {
    let l
    for (let i = 0; i < 10; i++) {
      if (!this.lines) return
      const line = this.lines[0]
      if (!line) return
      const new_ = line.getAttribute("x1")
      if (!l) l = new_
      this._destroyLines()
      this._createLines()
      if (new_ !== l) {
        l = new_
        break
      }
      await timeout(100)
    }
  }
}
