package org.matonos.store.source.types;

import org.matonos.store.source.types.Rating;
import org.matonos.store.source.types.AppBadge;
import org.matonos.store.source.types.RepoOption;

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
    /** Revision 4. Unix timestamp in seconds when this catalogue entry was added, if known. */
    long added;
    /** Revision 7. Backend supplied badges; unknown symbols are rendered generically. */
    @nullable AppBadge[] badges;
    /** Revision 13. Repository choices, highest priority first. */
    @nullable RepoOption[] repoOptions;
}
