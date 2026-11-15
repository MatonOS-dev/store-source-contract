package org.matonos.store.source;

import org.matonos.store.source.AgeRating;
import org.matonos.store.source.AntiFeature;
import org.matonos.store.source.AppListing;
import org.matonos.store.source.Safety;

/** Everything about one app. Sizes in bytes, -1 = unknown. */
parcelable AppDetails {
    AppListing listing;
    String description;
    String[] screenshots;
    String[] permissions;
    @nullable String license; @nullable String homepage;
    long downloadSize = -1; long installedSize = -1;
    @nullable Safety safety;
    @nullable AntiFeature[] antiFeatures;
    @nullable AgeRating ageRating;
}
