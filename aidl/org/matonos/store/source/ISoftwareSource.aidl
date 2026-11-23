package org.matonos.store.source;

import android.os.ParcelFileDescriptor;
import org.matonos.store.source.types.AppDetails;
import org.matonos.store.source.types.Review;
import org.matonos.store.source.types.SourceInfo;
import org.matonos.store.source.types.SourceSetting;
import org.matonos.store.source.types.ActionResult;
import org.matonos.store.source.IInstallCallback;

/** A source supplies one indexed catalogue; the store owns all catalogue queries. */
interface ISoftwareSource {
    /** Breaking catalogue contract. */
    const int VERSION = 5;
    const int REVISION = 2;
    const int CAP_AGE_RATINGS = 1 << 1;
    const int CAP_REVIEWS = 1 << 2;
    const int CAP_ANTI_FEATURES = 1 << 3;
    const int CAP_PERMISSIONS = 1 << 4;
    const int CAP_REQUIRES_SETUP = 1 << 6;

    SourceInfo info();
    /** Read-only UTF-8 JSON catalogue file descriptor. */
    ParcelFileDescriptor catalogue();
    /** Cheap monotonic generation, changed whenever catalogue contents change. */
    long catalogueVersion();
    AppDetails details(String id, String repo);
    Review[] reviews(String id, int offset, int limit);
    SourceSetting[] settings();
    @nullable String setSetting(String id, @nullable String value);
    ActionResult runAction(String id, in String[] values, boolean confirmed);
    void install(String id, String repo, String operationId, IInstallCallback callback);
    /** Install a caller-selected local .flatpak bundle. allowUnsigned must be
     * explicitly true to accept bundles without a commit signature. */
    void installLocalFile(in ParcelFileDescriptor file, String displayName,
            boolean allowUnsigned, String operationId, IInstallCallback callback);
    void cancel(String operationId);
    boolean running(String operationId);
    /**
     * Revision 1. Android packages this source installed that no installed app
     * needs any more (unused runtimes, extensions, locales). The store removes
     * the ones recorded to this source.
     */
    String[] unusedPackages();
}
