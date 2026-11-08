import "/gar-components/camera-input.mjs";
import "/gar-components/connection-status.mjs";
import "/gar-components/display.mjs";
import "/gar-components/rotary.mjs";

class TxBridgeAdapter extends EventTarget {
  #socket = null;
  #retry = null;
  #state = null;
  connected = false;

  constructor() {
    super();
    this.connect();
  }

  get state() { return this.#state; }

  send(message) {
    if (this.#socket?.readyState === WebSocket.OPEN) {
      this.#socket.send(JSON.stringify(message));
    }
  }

  close() {
    clearTimeout(this.#retry);
    this.#retry = null;
    this.#socket?.close();
    this.#socket = null;
  }

  connect() {
    const protocol = location.protocol === "https:" ? "wss:" : "ws:";
    const socket = new WebSocket(`${protocol}//${location.host}/ws`);
    this.#socket = socket;
    socket.addEventListener("open", () => {
      if (this.#socket !== socket) return;
      this.connected = true;
      this.emit("connection", { connected: true });
    });
    socket.addEventListener("message", ({ data }) => {
      if (this.#socket !== socket) return;
      try {
        const message = JSON.parse(data);
        if (message.type === "init") this.#state = message.state;
        this.emit("message", message);
      } catch { /* Ignore malformed bridge messages. */ }
    });
    socket.addEventListener("close", () => {
      if (this.#socket !== socket) return;
      this.connected = false;
      this.emit("connection", { connected: false });
      clearTimeout(this.#retry);
      this.#retry = setTimeout(() => this.connect(), 1500);
    });
  }

  emit(type, detail) {
    this.dispatchEvent(new CustomEvent(type, { detail }));
  }
}

const bridge = new TxBridgeAdapter();
const camera = document.querySelector("gar-camera-input");
const display = document.querySelector("#ili9341-display");
const rotary = document.querySelector("#rotary");
const status = document.querySelector("#bridge-status");

status.source = bridge;
camera.endpoint = "/camera-input/ws";
rotary.addEventListener("gar-rotary-input", ({ detail }) => {
  bridge.send(detail.type === "press"
    ? { type: "rotary_press" }
    : { type: "rotary_rotate", direction: detail.direction });
});

bridge.addEventListener("message", ({ detail: message }) => {
  const displayState = message.type === "init"
    ? message.state?.spi?.ili9341
    : message.type === "ili9341" ? message : null;
  if (displayState?.pixels) {
    const width = Number(displayState.width) || 320;
    const height = Number(displayState.height) || 240;
    const bytes = Uint8Array.from(atob(displayState.pixels), (character) => character.charCodeAt(0));
    if (bytes.length === width * height * 2) {
      display.width = width;
      display.height = height;
      display.writeFrame(bytes);
    }
  }

  const counter = message.type === "init"
    ? message.state?.gpio?.rotary?.counter
    : message.type === "rotary" ? message.counter : undefined;
  if (counter !== undefined && counter !== null) rotary.value = counter;
});

window.addEventListener("pagehide", () => bridge.close(), { once: true });
