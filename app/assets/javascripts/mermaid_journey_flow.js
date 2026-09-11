function initJourneyFlowDiagram() {
  if (!window.mermaid) return;

  var node = document.getElementById("journey-flow-diagram");
  if (!node || node.dataset.journeyFlowInitialized === "true") return;

  var parent = node.parentNode;
  if (!parent) return;

  mermaid.initialize({
    startOnLoad: true,
    securityLevel: "loose",
    flowchart: {
      useMaxWidth: false,
      htmlLabels: true
    }
  });

  mermaid.run({ nodes: [node] });

  var wrapper = document.createElement("div");
  wrapper.className = "journey-flow-wrapper";

  var wrapperStyle = wrapper.style;
  wrapperStyle.position = "relative";
  wrapperStyle.display = "flex";
  wrapperStyle.flexDirection = "column";
  wrapperStyle.justifyContent = "flex-start";
  wrapperStyle.border = "1px solid #b1b4b6";
  wrapperStyle.background = "#fff";
  wrapperStyle.padding = "16px";
  wrapperStyle.maxHeight = "calc(100vh - 120px)";
  wrapperStyle.minHeight = "420px";
  wrapperStyle.width = "100%";
  wrapperStyle.maxWidth = "100%";
  wrapperStyle.overflow = "hidden";

  var controls = document.createElement("div");
  controls.className = "journey-flow-controls";

  var controlsStyle = controls.style;
  controlsStyle.position = "relative";
  controlsStyle.zIndex = "2";
  controlsStyle.display = "flex";
  controlsStyle.gap = "8px";
  controlsStyle.marginBottom = "12px";
  controlsStyle.alignItems = "center";
  controlsStyle.flexShrink = "0";

  function buildButton(label, ariaLabel, onClick) {
    var button = document.createElement("button");
    button.type = "button";
    button.textContent = label;
    button.setAttribute("aria-label", ariaLabel);
    button.addEventListener("click", onClick);
    return button;
  }

  controls.appendChild(buildButton("+", "Zoom in", function() {
    zoomBy(1.15);
  }));

  controls.appendChild(buildButton("−", "Zoom out", function() {
    zoomBy(0.85);
  }));

  controls.appendChild(buildButton("Reset", "Reset zoom", function() {
    resetView();
  }));

  wrapper.appendChild(controls);
  parent.insertBefore(wrapper, node);
  wrapper.appendChild(node);

  var state = {
    scale: 1,
    minScale: 0.4,
    maxScale: 6,
    fitScale: 1,
    hasUserZoomed: false,
    translateX: 0,
    translateY: 0,
    isDragging: false,
    dragStartX: 0,
    dragStartY: 0,
    dragOriginX: 0,
    dragOriginY: 0
  };

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  function applyTransform() {
    node.style.transform = "translate(" + state.translateX + "px, " + state.translateY + "px) scale(" + state.scale + ")";
  }

  function centreDiagram() {
    var diagramWidth = node.scrollWidth || node.getBoundingClientRect().width || 0;
    var wrapperWidth = wrapper.clientWidth || 0;

    if (diagramWidth > 0 && wrapperWidth > 0) {
      state.fitScale = clamp(wrapperWidth / diagramWidth, state.minScale, 1);

      if (!state.hasUserZoomed && state.scale === 1) {
        state.scale = state.fitScale;
      }
    }

    var scaledWidth = diagramWidth * state.scale;
    state.translateX = (wrapperWidth - scaledWidth) / 2;
    state.translateY = 0;
    applyTransform();
  }

  function zoomBy(factor) {
    state.hasUserZoomed = true;
    state.scale = clamp(state.scale * factor, state.minScale, state.maxScale);
    centreDiagram();
  }

  function resetView() {
    state.hasUserZoomed = false;
    state.scale = state.fitScale;
    state.translateX = 0;
    state.translateY = 0;
    centreDiagram();
  }

  node.addEventListener("pointerdown", function(event) {
    if (event.target.closest("a")) return;

    state.isDragging = true;
    state.dragStartX = event.clientX;
    state.dragStartY = event.clientY;
    state.dragOriginX = state.translateX;
    state.dragOriginY = state.translateY;
    node.style.cursor = "grabbing";
    node.setPointerCapture(event.pointerId);
  });

  node.addEventListener("pointermove", function(event) {
    if (!state.isDragging) return;

    state.translateX = state.dragOriginX + (event.clientX - state.dragStartX);
    state.translateY = state.dragOriginY + (event.clientY - state.dragStartY);
    applyTransform();
  });

  node.addEventListener("pointerup", function(event) {
    state.isDragging = false;
    node.style.cursor = "grab";
    node.releasePointerCapture(event.pointerId);
  });

  node.addEventListener("pointerleave", function() {
    state.isDragging = false;
    node.style.cursor = "grab";
  });

  node.classList.remove("govuk-visually-hidden");
  node.style.position = "relative";
  node.style.zIndex = "1";
  node.style.transformOrigin = "0 0";
  node.style.transition = "transform 0.1s ease-out";
  node.style.display = "block";
  node.style.width = "auto";
  node.style.maxWidth = "100%";
  node.style.height = "auto";
  node.style.minHeight = "0";
  node.style.cursor = "grab";
  node.dataset.journeyFlowInitialized = "true";

  requestAnimationFrame(function() {
    requestAnimationFrame(centreDiagram);
  });
}

document.addEventListener("DOMContentLoaded", initJourneyFlowDiagram);
document.addEventListener("turbo:load", initJourneyFlowDiagram);
