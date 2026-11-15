package org.matonos.store.source;

import org.matonos.store.source.Rating;

/** One row of a list (search, installed, updates). */
parcelable AppListing {
    String id; String name; String summary; String icon; String developer;
    @nullable Rating rating;
    boolean installed;
    @nullable String versionName; @nullable String origin; @nullable String packageName;
}
