import { PerfumeDatabase } from "./database.js";

const database = new PerfumeDatabase();
const state = {
  records: [],
  search: "",
  brand: "",
  season: "",
  day: "",
  favoritesOnly: false,
  editingId: null,
  photo: null,
  cardUrls: [],
  previewUrl: null,
  toastTimer: null
};

const elements = {
  count: document.querySelector("#collection-count"),
  countLabel: document.querySelector("#count-label"),
  search: document.querySelector("#search-input"),
  brand: document.querySelector("#brand-filter"),
  season: document.querySelector("#season-filter"),
  dayButtons: [...document.querySelectorAll("[data-day]")],
  favoriteFilter: document.querySelector("#favorite-filter"),
  clearFilters: document.querySelector("#clear-filters"),
  resultsLabel: document.querySelector("#results-label"),
  grid: document.querySelector("#perfume-grid"),
  empty: document.querySelector("#empty-state"),
  noResults: document.querySelector("#no-results"),
  editor: document.querySelector("#editor-dialog"),
  form: document.querySelector("#perfume-form"),
  editorTitle: document.querySelector("#editor-title"),
  photo: document.querySelector("#photo-preview"),
  photoPlaceholder: document.querySelector("#photo-placeholder"),
  removePhoto: document.querySelector("#remove-photo"),
  cameraInput: document.querySelector("#camera-input"),
  libraryInput: document.querySelector("#library-input"),
  deleteButton: document.querySelector("#delete-button"),
  toast: document.querySelector("#toast"),
  importInput: document.querySelector("#import-input")
};

function escapeHTML(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  })[character]);
}

function newId() {
  if (crypto.randomUUID) return crypto.randomUUID();
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = [...bytes].map((byte) => byte.toString(16).padStart(2, "0")).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function normalizeList(value) {
  return String(value || "").split(",").map((item) => item.trim()).filter(Boolean);
}

function revokeCardUrls() {
  state.cardUrls.forEach((url) => URL.revokeObjectURL(url));
  state.cardUrls = [];
}

function imageURL(blob) {
  if (!blob) return "";
  const url = URL.createObjectURL(blob);
  state.cardUrls.push(url);
  return url;
}

function updateBrandOptions() {
  const current = state.brand;
  const brands = [...new Set(state.records.map((record) => record.brand.trim()).filter(Boolean))]
    .sort((a, b) => a.localeCompare(b, "it", { sensitivity: "base" }));
  elements.brand.innerHTML = '<option value="">Tutte le marche</option>' + brands
    .map((brand) => `<option value="${escapeHTML(brand)}">${escapeHTML(brand)}</option>`).join("");
  elements.brand.value = brands.includes(current) ? current : "";
  state.brand = elements.brand.value;
}

function filteredRecords() {
  const query = state.search.toLocaleLowerCase("it").trim();
  return state.records.filter((record) => {
    const matchesSearch = !query || record.name.toLocaleLowerCase("it").includes(query)
      || record.brand.toLocaleLowerCase("it").includes(query);
    const matchesBrand = !state.brand || record.brand === state.brand;
    const matchesSeason = !state.season || record.seasons.includes(state.season);
    const matchesDay = !state.day || record[state.day === "day" ? "dayUse" : "eveningUse"];
    const matchesFavorite = !state.favoritesOnly || record.isFavorite;
    return matchesSearch && matchesBrand && matchesSeason && matchesDay && matchesFavorite;
  });
}

function render() {
  revokeCardUrls();
  updateBrandOptions();

  const shown = filteredRecords();
  const total = state.records.length;
  elements.count.textContent = total;
  elements.countLabel.textContent = total === 1 ? " fragranza" : " fragranze";
  elements.favoriteFilter.setAttribute("aria-pressed", String(state.favoritesOnly));
  elements.season.value = state.season;
  elements.dayButtons.forEach((button) => {
    const active = button.dataset.day === state.day;
    button.classList.toggle("active", active);
    button.setAttribute("aria-pressed", String(active));
  });

  const hasFilters = Boolean(state.search || state.brand || state.season || state.day || state.favoritesOnly);
  elements.resultsLabel.textContent = hasFilters
    ? `${shown.length} ${shown.length === 1 ? "risultato" : "risultati"}`
    : "Tutte le fragranze";
  elements.grid.hidden = shown.length === 0;
  elements.empty.hidden = total !== 0 || hasFilters;
  elements.noResults.hidden = shown.length !== 0 || total === 0;

  elements.grid.innerHTML = shown.map((record, index) => {
    const tags = [...record.seasons.slice(0, 1), ...(record.repurchase ? ["Da ricomprare"] : [])];
    const photo = record.image
      ? `<img src="${imageURL(record.image)}" alt="Flacone di ${escapeHTML(record.name)}" loading="lazy">`
      : `<span class="card-bottle" aria-hidden="true"></span><span class="card-initial" aria-hidden="true">${escapeHTML(record.brand.slice(0, 1).toUpperCase())}</span>`;
    return `<article class="perfume-card" style="animation-delay:${Math.min(index * 32, 192)}ms">
      <button type="button" class="card-open" data-open="${escapeHTML(record.id)}" aria-label="Apri ${escapeHTML(record.name)} di ${escapeHTML(record.brand)}">
        <span class="card-photo">${photo}</span>
        <span class="card-info">
          <span class="card-brand">${escapeHTML(record.brand)}</span>
          <span class="card-name">${escapeHTML(record.name)}</span>
          <span class="card-family">${escapeHTML(record.family || "Famiglia non specificata")}</span>
          ${tags.length ? `<span class="card-tags">${tags.map((tag) => `<span class="card-tag">${escapeHTML(tag)}</span>`).join("")}</span>` : ""}
        </span>
      </button>
      <button type="button" class="card-favorite" data-favorite="${escapeHTML(record.id)}" aria-pressed="${record.isFavorite}" aria-label="${record.isFavorite ? "Rimuovi dai preferiti" : "Aggiungi ai preferiti"}: ${escapeHTML(record.name)}">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.8 8.7c0 5.1-8.8 11-8.8 11s-8.8-5.9-8.8-11A4.7 4.7 0 0 1 12 6a4.7 4.7 0 0 1 8.8 2.7Z"/></svg>
      </button>
    </article>`;
  }).join("");
}

function showToast(message) {
  clearTimeout(state.toastTimer);
  elements.toast.textContent = message;
  elements.toast.classList.add("visible");
  state.toastTimer = setTimeout(() => elements.toast.classList.remove("visible"), 3000);
}

function setPhoto(blob) {
  if (state.previewUrl) URL.revokeObjectURL(state.previewUrl);
  state.photo = blob || null;
  state.previewUrl = state.photo ? URL.createObjectURL(state.photo) : null;
  elements.photo.hidden = !state.previewUrl;
  elements.photoPlaceholder.hidden = Boolean(state.previewUrl);
  elements.removePhoto.hidden = !state.previewUrl;
  elements.photo.removeAttribute("src");
  if (state.previewUrl) elements.photo.src = state.previewUrl;
  elements.cameraInput.value = "";
  elements.libraryInput.value = "";
}

function openEditor(record = null) {
  state.editingId = record?.id || null;
  elements.form.reset();
  elements.editorTitle.textContent = record ? "La tua fragranza" : "Nuova fragranza";
  elements.deleteButton.hidden = !record;

  const fields = elements.form.elements;
  for (const name of ["brand", "name", "family", "accords", "topNotes", "heartNotes", "baseNotes", "personalNotes"]) {
    fields.namedItem(name).value = record ? (
      name === "accords" ? record.accords.join(", ") : record[name] || ""
    ) : "";
  }
  for (const name of ["longevity", "sillage"]) {
    fields.namedItem(name).value = record ? record[name] : 5;
    document.querySelector(`[data-output="${name}"]`).value = fields.namedItem(name).value;
  }
  for (const name of ["dayUse", "eveningUse", "isFavorite", "repurchase"]) {
    fields.namedItem(name).checked = Boolean(record?.[name]);
  }
  document.querySelectorAll('[data-choice-group="seasons"] input').forEach((input) => {
    input.checked = Boolean(record?.seasons.includes(input.value));
  });
  fields.namedItem("occasions").value = record ? record.occasions.join(", ") : "";
  setPhoto(record?.image || null);

  if (!elements.editor.open) elements.editor.showModal();
  requestAnimationFrame(() => fields.namedItem("brand").focus({ preventScroll: true }));
}

function closeEditor() {
  elements.editor.close();
  if (state.previewUrl) URL.revokeObjectURL(state.previewUrl);
  state.previewUrl = null;
  state.photo = null;
}

function formRecord() {
  const fields = elements.form.elements;
  const previous = state.records.find((record) => record.id === state.editingId);
  return {
    id: previous?.id || newId(),
    brand: fields.namedItem("brand").value.trim(),
    name: fields.namedItem("name").value.trim(),
    family: fields.namedItem("family").value,
    accords: normalizeList(fields.namedItem("accords").value),
    topNotes: fields.namedItem("topNotes").value.trim(),
    heartNotes: fields.namedItem("heartNotes").value.trim(),
    baseNotes: fields.namedItem("baseNotes").value.trim(),
    longevity: Number(fields.namedItem("longevity").value),
    sillage: Number(fields.namedItem("sillage").value),
    seasons: [...document.querySelectorAll('[data-choice-group="seasons"] input:checked')].map((input) => input.value),
    occasions: normalizeList(fields.namedItem("occasions").value),
    dayUse: fields.namedItem("dayUse").checked,
    eveningUse: fields.namedItem("eveningUse").checked,
    personalNotes: fields.namedItem("personalNotes").value.trim(),
    isFavorite: fields.namedItem("isFavorite").checked,
    repurchase: fields.namedItem("repurchase").checked,
    image: state.photo,
    createdAt: previous?.createdAt || new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
}

async function saveRecord(event) {
  event.preventDefault();
  if (!elements.form.reportValidity()) return;
  const record = formRecord();
  try {
    await database.put(record);
    const index = state.records.findIndex((item) => item.id === record.id);
    if (index < 0) state.records.unshift(record);
    else state.records[index] = record;
    render();
    closeEditor();
    showToast(state.editingId ? "Scheda aggiornata." : "Profumo aggiunto alla collezione.");
    state.editingId = null;
  } catch (error) {
    showToast(error.name === "QuotaExceededError"
      ? "Spazio esaurito sul dispositivo. Prova una foto più piccola."
      : "Non è stato possibile salvare. Esporta un backup e riprova.");
  }
}

async function deleteRecord() {
  const record = state.records.find((item) => item.id === state.editingId);
  if (!record || !window.confirm(`Vuoi eliminare ${record.name} di ${record.brand}?`)) return;
  try {
    await database.delete(record.id);
    state.records = state.records.filter((item) => item.id !== record.id);
    render();
    closeEditor();
    showToast("Fragranza eliminata.");
    state.editingId = null;
  } catch {
    showToast("Non è stato possibile eliminare questa scheda.");
  }
}

async function toggleFavorite(id) {
  const record = state.records.find((item) => item.id === id);
  if (!record) return;
  const updated = { ...record, isFavorite: !record.isFavorite, updatedAt: new Date().toISOString() };
  try {
    await database.put(updated);
    state.records = state.records.map((item) => item.id === id ? updated : item);
    render();
  } catch {
    showToast("Non è stato possibile aggiornare il preferito.");
  }
}

function blobToBase64(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).split(",", 2)[1] || "");
    reader.onerror = () => reject(reader.error || new Error("Impossibile leggere una foto."));
    reader.readAsDataURL(blob);
  });
}

async function exportCollection() {
  try {
    const perfumes = await Promise.all(state.records.map(async (record) => {
      const { image, ...fields } = record;
      return { ...fields, image: image ? { type: image.type || "image/jpeg", data: await blobToBase64(image) } : null };
    }));
    const backup = {
      app: "Naso Personale",
      version: 1,
      exportedAt: new Date().toISOString(),
      perfumes
    };
    const blob = new Blob([JSON.stringify(backup, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `naso-personale-${new Date().toISOString().slice(0, 10)}.json`;
    document.body.append(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    showToast("Backup esportato.");
  } catch {
    showToast("Esportazione non riuscita. Riprova con più spazio disponibile.");
  }
}

function base64ToBlob(value, type) {
  const bytes = atob(value);
  const parts = [];
  for (let offset = 0; offset < bytes.length; offset += 1024 * 1024) {
    const slice = bytes.slice(offset, offset + 1024 * 1024);
    const chunk = new Uint8Array(slice.length);
    for (let index = 0; index < slice.length; index += 1) chunk[index] = slice.charCodeAt(index);
    parts.push(chunk);
  }
  return new Blob(parts, { type: type || "image/jpeg" });
}

function normalizeImportedRecord(item) {
  if (!item || typeof item.brand !== "string" || typeof item.name !== "string"
      || !item.brand.trim() || !item.name.trim()) {
    throw new Error("Nel backup c’è una scheda senza marca o nome.");
  }
  let image = null;
  if (item.image?.data) {
    if (typeof item.image.data !== "string" || item.image.data.length > 80_000_000) {
      throw new Error("Una foto del backup è troppo grande o non valida.");
    }
    image = base64ToBlob(item.image.data, item.image.type);
  }
  const list = (value) => Array.isArray(value) ? value.filter((entry) => typeof entry === "string") : [];
  const rating = (value) => Math.min(10, Math.max(1, Number(value) || 5));
  return {
    id: typeof item.id === "string" && item.id ? item.id : newId(),
    brand: item.brand.trim(), name: item.name.trim(),
    family: typeof item.family === "string" ? item.family : "",
    accords: list(item.accords),
    topNotes: typeof item.topNotes === "string" ? item.topNotes : "",
    heartNotes: typeof item.heartNotes === "string" ? item.heartNotes : "",
    baseNotes: typeof item.baseNotes === "string" ? item.baseNotes : "",
    longevity: rating(item.longevity), sillage: rating(item.sillage),
    seasons: list(item.seasons), occasions: list(item.occasions),
    dayUse: Boolean(item.dayUse), eveningUse: Boolean(item.eveningUse),
    personalNotes: typeof item.personalNotes === "string" ? item.personalNotes : "",
    isFavorite: Boolean(item.isFavorite), repurchase: Boolean(item.repurchase),
    image,
    createdAt: typeof item.createdAt === "string" ? item.createdAt : new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
}

async function importCollection(file) {
  try {
    const backup = JSON.parse(await file.text());
    if (!backup || backup.app !== "Naso Personale" || backup.version !== 1 || !Array.isArray(backup.perfumes)) {
      throw new Error("Il file non è un backup valido di Naso Personale.");
    }
    if (backup.perfumes.length > 10000) throw new Error("Il backup contiene troppe schede.");
    const records = backup.perfumes.map(normalizeImportedRecord);
    const replace = window.confirm("Vuoi sostituire la collezione attuale?\n\nOK: sostituisci tutto. Annulla: unisci il backup (le schede con lo stesso ID vengono aggiornate).");
    await database.merge(records, replace);
    state.records = await database.getAll();
    render();
    showToast(`${records.length} ${records.length === 1 ? "scheda importata" : "schede importate"}.`);
  } catch (error) {
    showToast(error instanceof SyntaxError ? "Il file selezionato non contiene JSON valido." : error.message || "Importazione non riuscita.");
  } finally {
    elements.importInput.value = "";
  }
}

function clearFilters() {
  state.search = "";
  state.brand = "";
  state.season = "";
  state.day = "";
  state.favoritesOnly = false;
  elements.search.value = "";
  render();
}

function bindEvents() {
  document.querySelectorAll("#add-button, .empty-add-button").forEach((button) => {
    button.addEventListener("click", () => openEditor());
  });
  document.querySelector("#export-button").addEventListener("click", exportCollection);
  document.querySelector("#import-button").addEventListener("click", () => elements.importInput.click());
  elements.importInput.addEventListener("change", (event) => {
    if (event.target.files?.[0]) importCollection(event.target.files[0]);
  });
  elements.search.addEventListener("input", () => { state.search = elements.search.value; render(); });
  elements.brand.addEventListener("change", () => { state.brand = elements.brand.value; render(); });
  elements.season.addEventListener("change", () => { state.season = elements.season.value; render(); });
  elements.dayButtons.forEach((button) => button.addEventListener("click", () => {
    state.day = button.dataset.day;
    render();
  }));
  elements.favoriteFilter.addEventListener("click", () => {
    state.favoritesOnly = !state.favoritesOnly;
    render();
  });
  elements.clearFilters.addEventListener("click", clearFilters);
  document.querySelector("#no-results-clear").addEventListener("click", clearFilters);
  elements.grid.addEventListener("click", (event) => {
    const favoriteButton = event.target.closest("[data-favorite]");
    if (favoriteButton) {
      event.stopPropagation();
      toggleFavorite(favoriteButton.dataset.favorite);
      return;
    }
    const openButton = event.target.closest("[data-open]");
    if (openButton) openEditor(state.records.find((record) => record.id === openButton.dataset.open));
  });
  document.querySelectorAll("[data-close-editor]").forEach((button) => button.addEventListener("click", closeEditor));
  elements.editor.addEventListener("click", (event) => {
    if (event.target === elements.editor) closeEditor();
  });
  elements.form.addEventListener("submit", saveRecord);
  elements.deleteButton.addEventListener("click", deleteRecord);
  elements.removePhoto.addEventListener("click", () => setPhoto(null));
  [elements.cameraInput, elements.libraryInput].forEach((input) => input.addEventListener("change", () => {
    const file = input.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      showToast("Scegli un’immagine valida.");
      input.value = "";
      return;
    }
    setPhoto(file);
  }));
  ["longevity", "sillage"].forEach((name) => {
    elements.form.elements.namedItem(name).addEventListener("input", (event) => {
      document.querySelector(`[data-output="${name}"]`).value = event.target.value;
    });
  });
  document.addEventListener("keydown", (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      elements.search.focus();
    }
  });
}

async function start() {
  bindEvents();
  try {
    state.records = await database.getAll();
    render();
    if (navigator.storage?.persist) navigator.storage.persist().catch(() => {});
  } catch (error) {
    showToast(error.message || "Archivio locale non disponibile.");
  }
  if ("serviceWorker" in navigator && (location.protocol === "https:" || location.hostname === "localhost")) {
    navigator.serviceWorker.register("./service-worker.js").catch(() => {
      showToast("Installazione offline non disponibile in questa sessione.");
    });
  }
}

start();