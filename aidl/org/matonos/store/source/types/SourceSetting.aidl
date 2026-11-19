package org.matonos.store.source.types;

/** Generic source preference, repository group, or action. Values are strings; booleans use true/false. */
parcelable SourceSetting {
    String id;
    String label;
    String type;
    @nullable String value;
    float min = 0;
    float max = 1;
    float step = 1;
    boolean readOnly = false;
    boolean removable = false;
    @nullable String[] lineValues;
    @nullable SourceSetting[] children;
    @nullable SourceSetting[] fields;
}
