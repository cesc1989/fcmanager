import "../css/base.css";
import "../css/header.css";
import "../css/controls.css";
import "../css/plantilla.css";
import "../css/form.css";
import "../css/card.css";
import "../css/bench.css";
import "../css/compare.css";
import "../css/formation.css";

// Modal de confirmación para liberar un jugador (vista Plantilla).
const releaseDialog = document.getElementById("release-dialog");

document.querySelectorAll(".js-release").forEach((button) => {
  button.addEventListener("click", () => {
    releaseDialog.querySelector("form").action = button.dataset.url;
    releaseDialog.querySelector(".js-release-name").textContent = button.dataset.name;
    releaseDialog.showModal();
  });
});

// Comparar: al cambiar el desplegable de un cuadro se envía su formulario.
document.querySelectorAll(".js-autosubmit select").forEach((select) => {
  select.addEventListener("change", () => select.form.requestSubmit());
});

// Jugador que se está arrastrando: true si sale del campo (Formación).
let dragFromPitch = false;

// Comparar y Formación: se arrastran los jugadores de la lista y las fichas del
// campo. En Comparar, soltar en un cuadro reescribe ?a=&b=; si el jugador ya
// estaba en el otro cuadro, los dos se intercambian (como el setCompare del
// prototipo). El servidor vuelve a validar los ids.
document.querySelectorAll(".bench-item[data-player-id], .token[data-player-id]").forEach((item) => {
  item.addEventListener("dragstart", (event) => {
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", item.dataset.playerId);
    dragFromPitch = item.closest("[data-slot]") !== null;
    item.classList.add("is-dragging");
  });

  item.addEventListener("dragend", () => item.classList.remove("is-dragging"));
});

document.querySelectorAll("[data-compare-box]").forEach((zone) => {
  zone.addEventListener("dragover", (event) => {
    event.preventDefault();
    zone.classList.add("is-over");
  });

  zone.addEventListener("dragleave", () => zone.classList.remove("is-over"));

  zone.addEventListener("drop", (event) => {
    event.preventDefault();
    zone.classList.remove("is-over");

    const id = event.dataTransfer.getData("text/plain");
    if (!id) return;

    const box = zone.dataset.compareBox;
    const other = box === "a" ? "b" : "a";
    const params = new URLSearchParams(window.location.search);

    if (params.get(other) === id) {
      const current = params.get(box);

      if (current) {
        params.set(other, current);
      } else {
        params.delete(other);
      }
    }

    params.set(box, id);
    window.location.search = params.toString();
  });
});

// Formación: soltar en un hueco coloca al jugador (intercambia si venía de otro
// hueco). Se envía el form oculto, como un clic normal.
const dropForm = document.getElementById("formation-drop-form");

document.querySelectorAll("[data-slot]").forEach((zone) => {
  zone.addEventListener("dragover", (event) => {
    event.preventDefault();
    zone.classList.add("is-over");
  });

  zone.addEventListener("dragleave", () => zone.classList.remove("is-over"));

  zone.addEventListener("drop", (event) => {
    event.preventDefault();
    zone.classList.remove("is-over");

    const id = event.dataTransfer.getData("text/plain");
    if (!id || !dropForm) return;

    dropForm.elements.slot.value = zone.dataset.slot;
    dropForm.elements.player_id.value = id;
    dropForm.submit();
  });
});

// Formación: soltar una ficha del campo en la lista la saca del once. Lo que
// viene de la lista no hace nada (evita recargar la página por nada).
const benchForm = document.getElementById("formation-bench-form");

document.querySelectorAll("[data-formation-bench]").forEach((zone) => {
  zone.addEventListener("dragover", (event) => {
    if (!dragFromPitch) return;

    event.preventDefault();
    zone.classList.add("is-over");
  });

  zone.addEventListener("dragleave", () => zone.classList.remove("is-over"));

  zone.addEventListener("drop", (event) => {
    event.preventDefault();
    zone.classList.remove("is-over");

    const id = event.dataTransfer.getData("text/plain");
    if (!id || !dragFromPitch || !benchForm) return;

    benchForm.elements.player_id.value = id;
    benchForm.submit();
  });
});

// Botones que abren un <dialog> por id (Vaciar en Formación).
document.querySelectorAll("[data-open-dialog]").forEach((button) => {
  button.addEventListener("click", () => {
    document.getElementById(button.dataset.openDialog)?.showModal();
  });
});
