package org.matonos.store.source.types;

/** Returned by ISoftwareSource.info(). version/revision = ISoftwareSource.VERSION/REVISION the plugin was built against; capabilities is a bitmask of ISoftwareSource.CAP_*. */
parcelable SourceInfo { int version; int revision; String name; String label; int capabilities; }
