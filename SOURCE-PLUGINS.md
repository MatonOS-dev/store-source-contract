# Store source plugins

A store backend is an app with a bound service that:

- handles the intent action `org.matonos.store.SOURCE`,
- requires `android:permission="org.matonos.permission.BIND_STORE_SOURCE"`
  (signature permission defined by the store; services without it are ignored),
- implements `org.matonos.store.source.ISoftwareSource`
  (`aidl/` next to this file — the single copy of the contract: the store and
  every plugin include this repository as a git submodule and add `aidl/` as
  an AIDL source dir. Method order is the transaction order).

Preinstalled (system) plugins are enabled by default. Any other plugin stays
off until the user enables it in the store.

## Data

Every call returns typed AIDL parcelables (package `org.matonos.store.source.types`, `aidl/.../types/`, is
the reference). `SourceInfo.version`/`revision` are the
`ISoftwareSource.VERSION`/`REVISION` the plugin was built against.
- `VERSION` is the API version, bumped on every breaking change; `REVISION`
  resets to 0 then. The store skips a plugin whose version differs from its own.
- `REVISION` is bumped on every compatible change (methods and parcelable
  fields appended at the end). Any revision works with any store of the same
  version: the store never calls a method newer than the plugin's revision, and
  readers skip parcelable fields they do not know.
- A field added in a revision must have a default that means what an older
  plugin means by leaving it out (`@nullable` or an explicit `= value`): a
  store reading an older plugin's parcelable gets that default. Each new method
  and each new field gets a compatibility test against the previous revision. Every list call (`search`, `installed`, `updates`, `reviews`, `repos`) is
paged with `offset`/`limit` because a binder transaction is capped at 1 MB; a
page shorter than `limit` is the last one.

`collection(kind, offset, limit)` is the revision 2 curated browse call for
`popular` or `new`; unsupported kinds return an empty page.

Revision 3 adds `getPopularApps(limit)`, returning `{app, score}` records. Scores
are backend-owned values from 0 to 10 so the store can merge sources. Sources
below revision 3 remain usable for other features; the store logs and skips
them in Popular. Revision 4 appends `AppListing.added`, a Unix timestamp in
seconds when a source knows when a catalogue entry was added. Revision 5 adds
repository enabled state, app count, refresh time, and `setRepoEnabled(id,
enabled)`; unknown counts and times use `-1` and `0` respectively. Revision 6
adds `addRepoNamed(name, url)` for source settings that let the user name a repo. Revision 7 appends backend-owned `AppListing.badges` (`id`, localisable `label`, Material Symbol `icon`). Revision 8 appends `AppDetails.descriptionMarkdown`; descriptions use CommonMark paragraphs, headings, lists, bold, italic, inline code and HTTP(S) links (no raw HTML or images). Revision 9 appends `Repo.builtIn` and `Repo.removable` for default repositories users may toggle but not delete. Revision 10 appends `SourceInfo.description` for backend-owned source text. Revision 11 appends `SourceInfo.addRepoFields`, the backend-labelled fields required when adding a repository.

`info()` returns `SourceInfo{version, revision, name, label, capabilities}`; `capabilities` is a
bitmask of `ISoftwareSource.CAP_*` (the store shows a feature only for sources
that declare it):
- `CAP_REPOSITORIES`: user-managed repositories; `repos/addRepo/delRepo`.
- `CAP_AGE_RATINGS`: details carry `ageRating`.
- `CAP_REVIEWS`: `reviews(id, offset, limit)` returns reviews (others are never asked).
- `CAP_ANTI_FEATURES`: details carry `antiFeatures`.
- `CAP_PERMISSIONS`: details carry `permissions` / `safety`.
- `CAP_LOGIN`: the source supports signing in (e.g. an Aurora backend). The
  store offers "Sign in", which starts the plugin's activity for action
  `org.matonos.store.SOURCE_LOGIN` (resolved inside the plugin package).
  Reserved: not wired in this version.
- `CAP_REQUIRES_SETUP` (a static requirement; `info()` never reports state):
  the user must configure the source before it is useful
  (example: a Huawei AppGallery source). When the user enables it, the store
  starts the plugin's activity for action `org.matonos.store.SOURCE_SETUP` for
  a result and enables the source only on RESULT_OK. Reserved: future version.
Any enabled source may call `IStore.update(id, result)` (bind action
`org.matonos.store.STORE`). The store checks that `id` is installed and
recorded to the calling source, then runs `install(id, repo)` on it with the recorded repo; anything else is
rejected. `result` gets the outcome of the whole install.

Ids are opaque and only mean something to the source that returned them.
An install candidate is (id, repo): `repo` is a `Repo.id` from `repos()`, or
`"1"` for a source without repositories. `search` returns one listing per
candidate, so an app in several repos appears once per repo; the store groups
them by app and lets the user pick the repo (a drop-down, later). `details`
and `install` take the pair. The store records (plugin package, id, repo) for
every installed package; updates and `IStore.update` stay on that repo, and
moving to another repo is a reinstall the user chooses.

Flatpak: REPOSITORIES, AGE_RATINGS, REVIEWS, PERMISSIONS. F-Droid:
REPOSITORIES, ANTI_FEATURES, PERMISSIONS.

- `search`, `installed`, `updates`: `AppListing[]` (`packageName` set when the
  Android package differs from `id`).
- `details`: `AppDetails` (the `AppListing` plus description, screenshots,
  permissions, sizes, safety, anti-features, age rating).
- `reviews`: `Review[]` (date in epoch ms). `repos`: `Repo[]`.

The store converts results to JS with Gson; field names match
`src/sources/Source.ts` in the software centre.

## Errors

Binder carries only some exceptions. A plugin reports a failure by throwing
one of these with a message (never by returning an empty result):
`IllegalArgumentException` (bad id/url), `IllegalStateException` (anything
else: network, repo, disk), `UnsupportedOperationException` (call outside the
declared capabilities), `SecurityException`. Any other exception does not cross
binder; it crashes the plugin process.

The store maps them as follows:
- a thrown exception above: that call fails with the plugin's message, shown
  to the user and logged with the plugin package;
- `DeadObjectException` (plugin crashed or was killed) or a binding that
  disconnects: the call fails with "<label> stopped", the store drops the
  binding and binds again on the next call; an operation in flight is reported
  failed;
- a plugin that cannot be bound or reports another VERSION: skipped and logged.

## Install and update

`install(id, repo, operationId, callback)` is used for both and returns at once; the
work runs in the background. The source downloads and verifies, reports
`progress`, and hands every package to the store with
`commit(operationId, packageName, names, files, removeSplits, result)`:
one PackageInstaller session per call, `names[i]` the APK name of read-only
`files[i]` (base.apk plus split APKs), `removeSplits` drops splits. A commit
with base.apk is a full install or update; one without it (splits and/or
`removeSplits` only) changes the installed package and keeps its other splits. The session is pinned to
`packageName` and requests update ownership. The store answers on
`result.result(ok, error)` once the session is final; the source commits a
dependent package only after its dependencies succeeded. When everything is
in, the source calls `done(operationId)`, or `failed(operationId, error)`.
Sources never install or uninstall; the store uninstalls by package name.

`cancel(operationId)` stops a running install: the source stops downloading,
abandons nothing the store has already committed, and ends with
`failed(operationId, "cancelled")`. The store abandons a session it has not
committed yet.

Keep-alive (revision 1): while an operation is in flight the store
periodically calls `running(operationId)`. `false` before the source called
`done`/`failed` means the source lost the operation: the store fails it
("<label> lost the operation") and abandons uncommitted sessions. A call that
throws `DeadObjectException` is handled as "<label> stopped" (see Errors).
`running` answers from the source's own operation table and never waits for
the operation's work, so a stuck download still shows as running; progress
reporting is how the user sees it stall.

Ownership: the store is the installer of every package. When a commit
succeeds it records which plugin supplied that package; `installed()` and
`updates()` are asked with that record in mind: the store passes a package to
a source for updates only if that source supplied it. A package available in
several sources stays with the source that installed it until the user
uninstalls it. `installed()` returns the packages the source knows it supplied
(its own state, e.g. Flatpak's installed refs); the store intersects that
with its record.

The ownership record is the store's own and outlives the source: if the
plugin is uninstalled or loses its data, the packages it supplied stay
recorded to it (shown as "source unavailable", no updates) and are never moved
to another source silently. Only the user moves a package to another source,
which is a reinstall from that source.

Dependencies (e.g. Flatpak runtimes as their own packages) can be uninstalled
on their own; nothing blocks it. Repair happens at launch: the app finds the
missing dependency in its signed deployment record, the source calls
`IStore.update(id)`, and the store runs `install(id, repo)`,
which on an installed app commits only what is missing. The source
keeps the dependency list itself, so a removed runtime is found even though its
package is gone.
