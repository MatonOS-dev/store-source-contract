package org.matonos.store.source;

import org.matonos.store.source.SafetyItem;

/** level: "safe" | "probably-safe" | "potentially-unsafe". */
parcelable Safety { String level; SafetyItem[] items; }
