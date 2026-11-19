package org.matonos.store.source.types;

parcelable ActionResult {
    @nullable String error;
    @nullable String confirmTitle;
    @nullable String confirmMessage;
    boolean launch = false;
}
