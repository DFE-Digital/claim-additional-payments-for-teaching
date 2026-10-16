document.addEventListener("DOMContentLoaded", function () {
  var container = document.querySelector(".journey-flow-container");
  if (!container) return;

  var canvas = container.querySelector("#journey-flow-diagram");
  var svg = canvas ? canvas.querySelector("svg") : null;
  if (!canvas || !svg) return;

  var state = {
    scale: 1,
    minScale: 0.6,
    maxScale: 2.5,
    translateX: 0,
    translateY: 0,
    dragging: false,
    startX: 0,
    startY: 0,
    originX: 0,
    originY: 0
  };

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  function getViewSize() {
    var rect = svg.getBoundingClientRect();
    return {
      width: svg.viewBox.baseVal && svg.viewBox.baseVal.width ? svg.viewBox.baseVal.width : (rect.width || svg.clientWidth || 1200),
      height: svg.viewBox.baseVal && svg.viewBox.baseVal.height ? svg.viewBox.baseVal.height : (rect.height || svg.clientHeight || 600)
    };
  }

  function applyTransform() {
    var view = getViewSize();
    var scaledWidth = view.width * state.scale;
    var scaledHeight = view.height * state.scale;
    var maxTranslateX = Math.max(0, scaledWidth - canvas.clientWidth);
    var maxTranslateY = Math.max(0, scaledHeight - canvas.clientHeight);

    state.translateX = clamp(state.translateX, -maxTranslateX, maxTranslateX);
    state.translateY = clamp(state.translateY, -maxTranslateY, maxTranslateY);

    svg.style.position = "absolute";
    svg.style.left = "0";
    svg.style.top = "0";
    svg.style.width = view.width + "px";
    svg.style.height = view.height + "px";
    svg.style.transform = "translate(" + state.translateX + "px, " + state.translateY + "px) scale(" + state.scale + ")";
    svg.style.transformOrigin = "0 0";
    svg.style.cursor = state.dragging ? "grabbing" : "grab";
    svg.style.pointerEvents = "auto";
  }

  function zoomBy(factor, pivotX, pivotY) {
    var previousScale = state.scale;
    var nextScale = clamp(previousScale * factor, state.minScale, state.maxScale);
    if (nextScale === previousScale) return;

    var rect = canvas.getBoundingClientRect();
    var centerX = typeof pivotX === "number" ? pivotX : rect.width / 2;
    var centerY = typeof pivotY === "number" ? pivotY : rect.height / 2;
    var worldX = (centerX - state.translateX) / previousScale;
    var worldY = (centerY - state.translateY) / previousScale;

    state.scale = nextScale;
    state.translateX = centerX - worldX * state.scale;
    state.translateY = centerY - worldY * state.scale;
    applyTransform();
  }

  function resetView() {
    state.scale = 1;
    state.translateX = 0;
    state.translateY = 0;
    applyTransform();
  }

  var zoomInButton = document.querySelector(".journey-flow-zoom-in");
  var zoomOutButton = document.querySelector(".journey-flow-zoom-out");
  var resetButton = document.querySelector(".journey-flow-reset");

  if (zoomInButton) {
    zoomInButton.addEventListener("click", function () {
      zoomBy(1.15);
    });
  }

  if (zoomOutButton) {
    zoomOutButton.addEventListener("click", function () {
      zoomBy(0.85);
    });
  }

  if (resetButton) {
    resetButton.addEventListener("click", function () {
      resetView();
    });
  }

  canvas.addEventListener("wheel", function (event) {
    event.preventDefault();
    if (!event.deltaY) return;

    var rect = canvas.getBoundingClientRect();
    var pointerX = event.clientX - rect.left;
    var pointerY = event.clientY - rect.top;
    var previousScale = state.scale;
    var nextScale = clamp(previousScale * (event.deltaY > 0 ? 0.9 : 1.1), state.minScale, state.maxScale);
    if (nextScale === previousScale) return;

    var worldX = (pointerX - state.translateX) / previousScale;
    var worldY = (pointerY - state.translateY) / previousScale;

    state.scale = nextScale;
    state.translateX = pointerX - worldX * state.scale;
    state.translateY = pointerY - worldY * state.scale;
    applyTransform();
  }, { passive: false });

  function startDrag(event) {
    if (event.button !== 0 && event.button !== undefined) return;
    if (event.target && event.target.closest && event.target.closest("a")) return;

    state.dragging = true;
    state.startX = event.clientX;
    state.startY = event.clientY;
    state.originX = state.translateX;
    state.originY = state.translateY;
  }

  function moveDrag(event) {
    if (!state.dragging) return;

    var deltaX = event.clientX - state.startX;
    var deltaY = event.clientY - state.startY;
    state.translateX = state.originX + deltaX;
    state.translateY = state.originY + deltaY;
    applyTransform();
  }

  function endDrag() {
    state.dragging = false;
  }

  canvas.addEventListener("pointerdown", startDrag);
  canvas.addEventListener("mousedown", startDrag);
  window.addEventListener("pointermove", moveDrag);
  window.addEventListener("mousemove", moveDrag);
  window.addEventListener("pointerup", endDrag);
  window.addEventListener("mouseup", endDrag);
  window.addEventListener("pointercancel", endDrag);

  applyTransform();
});
