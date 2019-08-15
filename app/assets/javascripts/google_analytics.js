window.dataLayer = window.dataLayer || [];
function gtag() {
  dataLayer.push(arguments);
}
gtag("js", new Date());

gtag("config", document.currentScript.getAttribute("data-ga-id"), { anonymize_ip: true });
