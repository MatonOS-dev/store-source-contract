package org.matonos.store.source;

import org.matonos.store.source.AppDetails;
import org.matonos.store.source.AppListing;
import org.matonos.store.source.IInstallCallback;
import org.matonos.store.source.Repo;
import org.matonos.store.source.Review;
import org.matonos.store.source.SourceInfo;

/**
 * A software source (store backend). Implemented by plugin apps, called only by
 * the software centre. Keep the method order: it is the transaction order.
 * Errors are thrown (IllegalArgumentException/IllegalStateException with a
 * message), never encoded as empty results.
 */
interface ISoftwareSource {
    /** Bumped on any incompatible change; the store skips plugins with another version. */
    const int VERSION = 2;

    const int CAP_REPOSITORIES = 1 << 0;
    const int CAP_AGE_RATINGS = 1 << 1;
    const int CAP_REVIEWS = 1 << 2;
    const int CAP_ANTI_FEATURES = 1 << 3;
    const int CAP_PERMISSIONS = 1 << 4;
    const int CAP_LOGIN = 1 << 5;
    const int CAP_REQUIRES_SETUP = 1 << 6;

    SourceInfo info();
    /** Results offset..offset+limit-1 (binder transactions are capped at 1 MB). */
    AppListing[] search(String term, int offset, int limit);
    AppDetails details(String id);
    Review[] reviews(String id);
    /** Apps this source installed. */
    AppListing[] installed();
    /** Installed apps with an update available. */
    AppListing[] updates();
    Repo[] repos();
    void addRepo(String url);
    void delRepo(String id);
    /** Prepares an install or update; the APKs come back through callback.commit(). */
    void install(String id, String operationId, IInstallCallback callback);
}
