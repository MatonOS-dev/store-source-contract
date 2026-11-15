package org.matonos.store.source;

import org.matonos.store.source.ICommitResult;

/**
 * Served by the store (bind action org.matonos.store.STORE) for source
 * plugins; any enabled source may call it.
 */
interface IStore {
    /**
     * Asks the store to update an app the calling source installed (it also
     * restores missing dependencies). The store checks that id is installed
     * and recorded to the caller, then runs install(id) on the caller. result
     * gets the outcome of the whole install.
     */
    void update(String id, ICommitResult result);
}
