import "../css/base.css";
import "../css/header.css";
import "../css/controls.css";
import "../css/plantilla.css";
import "../css/form.css";
import "../css/card.css";
import "../css/compare.css";

// Modal de confirmación para liberar un jugador (vista Plantilla).
const releaseDialog = document.getElementById("release-dialog");

document.querySelectorAll(".js-release").forEach((button) => {
  button.addEventListener("click", () => {
    releaseDialog.querySelector("form").action = button.dataset.url;
    releaseDialog.querySelector(".js-release-name").textContent = button.dataset.name;
    releaseDialog.showModal();
  });
});
