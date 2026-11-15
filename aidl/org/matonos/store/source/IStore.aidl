package org.matonos.store.source;

import org.matonos.store.source.ICommitResult;

/**
 * Served by the store (bind action org.matonos.store.STORE) for source
 * plugins. The store checks the caller's UID: it must be an enabled source
 * plugin declaring CAP_ALLOW_REPAIR.
 */
interface IStore {
    /**
     * Asks the store to run install(id) on the calling source to restore
     * missing dependencies of an installed app. With the plugin's "Allow
     * repairs" setting on, the store runs it at once (progress notification
     * only); off, it asks the user first. result gets the outcome of the whole
     * install (ok=false, "declined" when the user says no).
     */
    void repair(String id, ICommitResult result);
}
