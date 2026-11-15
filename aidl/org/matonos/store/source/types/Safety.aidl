package org.matonos.store.source.types;

import org.matonos.store.source.types.SafetyItem;

/** level: "safe" | "probably-safe" | "potentially-unsafe". */
parcelable Safety { String level; SafetyItem[] items; }
