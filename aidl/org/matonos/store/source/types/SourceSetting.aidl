package org.matonos.store.source.types;

/** Generic source preference, repository group, or action. Values are strings; booleans use true/false. */
parcelable SourceSetting {
    String id;
    String label;
    String type;
    @nullable String value;
    float min;
    float max;
    float step;
    boolean readOnly = false;
    boolean removable = false;
    @nullable SourceSetting[] children;
    @nullable SourceSetting[] fields;
}
