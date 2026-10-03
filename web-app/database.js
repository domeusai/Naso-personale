const DATABASE_NAME = "naso-personale-local";
const DATABASE_VERSION = 1;
const STORE_NAME = "perfumes";

function requestResult(request) {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error || new Error("Operazione non riuscita."));
  });
}

function transactionResult(transaction) {
  return new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve();
    transaction.onabort = () => reject(transaction.error || new Error("Salvataggio interrotto."));
    transaction.onerror = () => reject(transaction.error || new Error("Errore nel database locale."));
  });
}

export class PerfumeDatabase {
  constructor() {
    this.databasePromise = this.open();
  }

  open() {
    if (!("indexedDB" in globalThis)) {
      return Promise.reject(new Error("Questo browser non supporta IndexedDB."));
    }

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DATABASE_NAME, DATABASE_VERSION);
      request.onupgradeneeded = () => {
        const database = request.result;
        if (!database.objectStoreNames.contains(STORE_NAME)) {
          const store = database.createObjectStore(STORE_NAME, { keyPath: "id" });
          store.createIndex("brand", "brand", { unique: false });
          store.createIndex("favorite", "isFavorite", { unique: false });
          store.createIndex("updatedAt", "updatedAt", { unique: false });
        }
      };
      request.onsuccess = () => {
        const database = request.result;
        database.onversionchange = () => database.close();
        resolve(database);
      };
      request.onerror = () => reject(request.error || new Error("Impossibile aprire l’archivio locale."));
      request.onblocked = () => reject(new Error("Chiudi le altre schede di Naso Personale e riprova."));
    });
  }

  async getAll() {
    const database = await this.databasePromise;
    const transaction = database.transaction(STORE_NAME, "readonly");
    const request = transaction.objectStore(STORE_NAME).getAll();
    const [records] = await Promise.all([requestResult(request), transactionResult(transaction)]);
    return records.sort((a, b) => (b.updatedAt || "").localeCompare(a.updatedAt || ""));
  }

  async put(record) {
    const database = await this.databasePromise;
    const transaction = database.transaction(STORE_NAME, "readwrite");
    transaction.objectStore(STORE_NAME).put(record);
    await transactionResult(transaction);
  }

  async delete(id) {
    const database = await this.databasePromise;
    const transaction = database.transaction(STORE_NAME, "readwrite");
    transaction.objectStore(STORE_NAME).delete(id);
    await transactionResult(transaction);
  }

  async merge(records, replace = false) {
    const database = await this.databasePromise;
    const transaction = database.transaction(STORE_NAME, "readwrite");
    const store = transaction.objectStore(STORE_NAME);
    if (replace) store.clear();
    for (const record of records) store.put(record);
    await transactionResult(transaction);
  }
}