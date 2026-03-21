String etaConfidenceLabel(int itemCount) {
  if (itemCount <= 2) return 'High confidence';
  if (itemCount <= 4) return 'Medium confidence';
  return 'Medium confidence';
}
