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

`SourceInfo.version`/`revision` are the `ISoftwareSource.VERSION`/`REVISION` the plugin was built against. `VERSION` is bumped on every breaking change; the store skips plugins whose version differs.

`catalogue()` returns a read-only descriptor for a UTF-8 JSON document with this shape:

```json
{"format":1,"source":"org.example.source","generated":1730000000,"apps":[{"id":"org.example.app","name":"Example","summary":"Short description","icon":"https://example/icon.png","developer":"Example Org","installed":false,"repo":"stable","versionName":"2.0","packageName":"org.example.app","added":1730000000,"badges":[],"repoOptions":[{"repoId":"stable","name":"Stable","version":"2.0","installable":true}],"repoLabel":"Stable","repoPriority":100,"popularityScore":7.5,"currentVersionName":null,"signerMatches":false,"installable":true,"updateAvailable":false}]}
```

The top-level `format` is exactly 1. `source` is the plugin package and `generated` is Unix seconds. Each app is one install candidate per repository. The first fields through `repoOptions` are the complete `AppListing` shape. `packageName` is required for every app: it is the stable package identifier used for ratings and package ownership. F-Droid uses its Android package name; Flatpak uses `flatpak.<Flatpak app id>` (for example, `flatpak.org.kde.kate`), with no architecture or branch. Additional store-index fields are `repoLabel`, numeric `repoPriority` (larger is higher priority), numeric `popularityScore` (0 when unknown), `currentVersionName`, `signerMatches`, `installable`, and `updateAvailable`. Other nullable values may be JSON null; absent optional values have the same meaning. The store treats ids and repository ids as opaque. Plugins must stream JSON to a file in their private files directory and return a descriptor without materializing a second whole-catalogue object tree.

`catalogueVersion()` is a cheap monotonic generation. It changes when refresh, repository settings, or installed-package state changes alter catalogue contents. The store persists the last imported generation per plugin and reimports only when it differs. Querying, filtering, ordering, paging, repository choices, installed state, updates, New, and Popular belong to the store's local SQLite index.

`details(id, repo)` returns detail data for exactly that candidate, including the required package name on its `AppListing`; `reviews` remains paged. Settings/actions and install lifecycle calls retain their existing semantics. The catalogue eliminates the former `search`, `installed`, `updates`, `collection`, and `getPopularApps` calls.

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

`installLocalFile(file, displayName, allowUnsigned, operationId, callback)`
installs a local `.flatpak` bundle from a caller-owned `ParcelFileDescriptor`.
The source copies the file into leased operation storage before processing it.
The store must show its unverified-source warning and pass `allowUnsigned=true`
only after the user accepts; otherwise an unsigned bundle fails without a
package commit. The source reports `Local bundle signature: signed` or
`Local bundle signature: unsigned` through `progress` before submitting
packages. The same commit, cancel and terminal callback rules apply. This
method does not handle `.flatpakref` files.

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
