package org.matonos.store.source.types;

/** rating 1..5; date in epoch milliseconds. */
parcelable Review { String id; String author; int rating; String summary; String description; String version; long date; }
