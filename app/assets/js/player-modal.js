const modal = document.getElementById("player-modal");
const newButton = document.getElementById("btn-new");

if (modal && newButton) {
  newButton.addEventListener("click", () => modal.showModal());

  modal.querySelectorAll("[data-close]").forEach((button) => {
    button.addEventListener("click", () => modal.close());
  });

  modal.addEventListener("click", (event) => {
    if (event.target === modal) modal.close();
  });
}
