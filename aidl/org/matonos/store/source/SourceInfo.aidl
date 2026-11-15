package org.matonos.store.source;

/** Returned by ISoftwareSource.info(). version = ISoftwareSource.VERSION the plugin was built against; capabilities is a bitmask of ISoftwareSource.CAP_*. */
parcelable SourceInfo { int version; String name; String label; int capabilities; }
