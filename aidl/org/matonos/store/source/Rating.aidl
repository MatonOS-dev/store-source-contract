package org.matonos.store.source;

/** Average 0..5; histogram[i] = number of (i+1)-star ratings, length 5. */
parcelable Rating { float average; int count; int[] histogram; }
