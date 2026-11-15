package org.matonos.store.source.types;

import org.matonos.store.source.types.Rating;

/**
 * One row of a list (search, installed, updates): one install candidate.
 * (id, repo) names it; repo is a Repo.id, "1" for sources without repositories.
 */
parcelable AppListing {
    String id; String name; String summary; String icon; String developer;
    @nullable Rating rating;
    boolean installed;
    String repo = "1";
    @nullable String versionName; @nullable String packageName;
}
