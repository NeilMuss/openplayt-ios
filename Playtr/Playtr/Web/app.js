const handlers = window.webkit && window.webkit.messageHandlers;

function post(name, payload) {
  if (!handlers || !handlers[name]) {
    return;
  }
  handlers[name].postMessage(payload ?? {});
}

const state = {
  title: "No Track",
  artist: "",
  status: "Idle",
  position: 0,
  volume: 1,
  queueEnded: false,
};

function updateUI() {
  document.getElementById("title").textContent = state.title;
  document.getElementById("artist").textContent = state.artist;
  document.getElementById("status").textContent = state.queueEnded
    ? `${state.status} • Queue Ended`
    : state.status;
  document.getElementById("position").value = Math.round(state.position);
  document.getElementById("volume").value = state.volume;
  document.getElementById("play").textContent = state.status === "Playing" ? "Pause" : "Play";
}

window.playt = {
  updateState(nextState) {
    Object.assign(state, nextState);
    updateUI();
  },
};

document.getElementById("play").addEventListener("click", () => post("playPause"));
document.getElementById("next").addEventListener("click", () => post("next"));
document.getElementById("prev").addEventListener("click", () => post("previous"));
document.getElementById("position").addEventListener("input", (event) => {
  post("seek", { value: Number(event.target.value) });
});
document.getElementById("volume").addEventListener("input", (event) => {
  post("volume", { value: Number(event.target.value) });
});
document.getElementById("reload").addEventListener("click", () => post("reloadSample"));

updateUI();
