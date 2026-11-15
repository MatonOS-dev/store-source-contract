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
the reference). `SourceInfo.version` is the `ISoftwareSource.VERSION` the
plugin was built against; the store skips a plugin whose version differs. Failures are thrown with a message, never returned
as empty results. `search` pages with `offset`/`limit` because a binder
transaction is capped at 1 MB.

`info()` returns `SourceInfo{version, name, label, capabilities}`; `capabilities` is a
bitmask of `ISoftwareSource.CAP_*` (the store shows a feature only for sources
that declare it):
- `CAP_REPOSITORIES`: user-managed repositories; `repos/addRepo/delRepo`.
- `CAP_AGE_RATINGS`: details carry `ageRating`.
- `CAP_REVIEWS`: `reviews(id)` returns reviews (others are never asked).
- `CAP_ANTI_FEATURES`: details carry `antiFeatures`.
- `CAP_PERMISSIONS`: details carry `permissions` / `safety`.
- `CAP_LOGIN`: the source supports signing in (e.g. an Aurora backend). The
  store offers "Sign in", which starts the plugin's activity for action
  `org.matonos.store.SOURCE_LOGIN` (resolved inside the plugin package).
  Reserved: not wired in this version.
- `CAP_REQUIRES_SETUP`: the user must configure the source before it is useful
  (example: a Huawei AppGallery source). When the user enables it, the store
  starts the plugin's activity for action `org.matonos.store.SOURCE_SETUP` for
  a result and enables the source only on RESULT_OK. Reserved: future version.

Flatpak: REPOSITORIES, AGE_RATINGS, REVIEWS, PERMISSIONS. F-Droid:
REPOSITORIES, ANTI_FEATURES, PERMISSIONS.

- `search`, `installed`, `updates`: `AppListing[]` (`packageName` set when the
  Android package differs from `id`).
- `details`: `AppDetails` (the `AppListing` plus description, screenshots,
  permissions, sizes, safety, anti-features, age rating).
- `reviews`: `Review[]` (date in epoch ms). `repos`: `Repo[]`.

The store converts results to JS with Gson; field names match
`src/sources/Source.ts` in the software centre.

## Install and update

`install(id, operationId, callback)` is used for both and returns at once; the
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
