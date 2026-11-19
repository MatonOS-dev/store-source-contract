package org.matonos.store.source.types;

/** One repository that offers an app. Options arrive in backend priority order. */
parcelable RepoOption {
    String repoId;
    String name;
    @nullable String version;
    boolean installable = true;
    @nullable String note;
}
