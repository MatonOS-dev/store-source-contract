package org.matonos.store.source.types;

parcelable Repo {
    String id; String url; String label; boolean official; boolean broken;
    /** Revision 5. */
    boolean enabled = true;
    int appCount = -1;
    long lastRefreshed;
}
