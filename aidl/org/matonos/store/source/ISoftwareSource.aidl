package org.matonos.store.source;

import org.matonos.store.source.types.AppDetails;
import org.matonos.store.source.types.AppListing;
import org.matonos.store.source.types.PopularApp;
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
    /** API version: bumped on every breaking change; REVISION then resets to 0. */
    const int VERSION = 2;
    /**
     * Bumped on every compatible change (method or parcelable field appended at
     * the end). The store never calls a method newer than the plugin's revision.
     */
    const int REVISION = 6;

    const int CAP_REPOSITORIES = 1 << 0;
    const int CAP_AGE_RATINGS = 1 << 1;
    const int CAP_REVIEWS = 1 << 2;
    const int CAP_ANTI_FEATURES = 1 << 3;
    const int CAP_PERMISSIONS = 1 << 4;
    const int CAP_LOGIN = 1 << 5;
    const int CAP_REQUIRES_SETUP = 1 << 6;

    SourceInfo info();
    AppListing[] search(String term, int offset, int limit);
    AppDetails details(String id, String repo);
    Review[] reviews(String id, int offset, int limit);
    /** Installed packages that came from this source (store's record, see SOURCE-PLUGINS.md). */
    AppListing[] installed(int offset, int limit);
    /** Installed apps with an update available. */
    AppListing[] updates(int offset, int limit);
    Repo[] repos(int offset, int limit);
    void addRepo(String url);
    void delRepo(String id);
    /** Prepares an install or update; the APKs come back through callback.commit(). */
    void install(String id, String repo, String operationId, IInstallCallback callback);
    /** Stops a running install(); the source ends it with callback.failed(operationId, "cancelled"). Unknown or finished ids are ignored. */
    void cancel(String operationId);
    /**
     * Revision 1. Keep-alive state check: true while operationId is still being
     * worked on (not yet ended with done/failed). Must answer at once, never block
     * on the operation's own work.
     */
    boolean running(String operationId);
    /** Revision 2. Curated, paged browse collection (popular or new). */
    AppListing[] collection(String kind, int offset, int limit);
    /** Revision 3. Popular listings with backend-owned scores from 0 through 10. */
    PopularApp[] getPopularApps(int limit);
    /** Revision 5. Enables or disables a repository without removing its trust record. */
    void setRepoEnabled(String id, boolean enabled);
    /** Revision 6. Adds a repository with a user-visible label. */
    void addRepoNamed(String name, String url);
}
