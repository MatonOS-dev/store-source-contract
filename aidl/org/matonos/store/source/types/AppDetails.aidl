package org.matonos.store.source.types;

import org.matonos.store.source.types.AgeRating;
import org.matonos.store.source.types.AntiFeature;
import org.matonos.store.source.types.AppListing;
import org.matonos.store.source.types.Safety;

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
    /** Revision 8. CommonMark description; null means use description as Markdown. */
    @nullable String descriptionMarkdown;
}
