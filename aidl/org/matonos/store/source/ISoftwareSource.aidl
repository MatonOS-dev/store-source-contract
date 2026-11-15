package org.matonos.store.source;

import org.matonos.store.source.types.AppDetails;
import org.matonos.store.source.types.AppListing;
import org.matonos.store.source.IInstallCallback;
import org.matonos.store.source.types.Repo;
import org.matonos.store.source.types.Review;
import org.matonos.store.source.types.SourceInfo;

/**
 * A software source (store backend). Implemented by plugin apps, called only by
 * the software centre. Keep the method order: it is the transaction order.
 * Every list call is paged: items offset..offset+limit-1; a page shorter than
 * limit is the last (a binder transaction is capped at 1 MB).
 * Errors: see "Errors" in SOURCE-PLUGINS.md.
 */
interface ISoftwareSource {
    /**
     * Contract revision. Only compatible changes: methods appended at the end,
     * parcelable fields appended at the end. A plugin built against an older
     * VERSION keeps working; the store never calls methods newer than it.
     */
    const int VERSION = 2;

    const int CAP_REPOSITORIES = 1 << 0;
    const int CAP_AGE_RATINGS = 1 << 1;
    const int CAP_REVIEWS = 1 << 2;
    const int CAP_ANTI_FEATURES = 1 << 3;
    const int CAP_PERMISSIONS = 1 << 4;
    const int CAP_LOGIN = 1 << 5;
    const int CAP_REQUIRES_SETUP = 1 << 6;

    SourceInfo info();
    AppListing[] search(String term, int offset, int limit);
    AppDetails details(String id);
    Review[] reviews(String id, int offset, int limit);
    /** Apps this source installed. */
    AppListing[] installed(int offset, int limit);
    /** Installed apps with an update available. */
    AppListing[] updates(int offset, int limit);
    Repo[] repos(int offset, int limit);
    void addRepo(String url);
    void delRepo(String id);
    /** Prepares an install or update; the APKs come back through callback.commit(). */
    void install(String id, String operationId, IInstallCallback callback);
}
