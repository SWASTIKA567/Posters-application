// NCR (National Capital Region) Validation Helper

/// Checks whether a given state, district, or pincode is located within the
/// official National Capital Region (NCR).
bool isNcrRegion({
  required String state,
  required String district,
  required String pincode,
}) {
  final cleanState = state.toLowerCase().trim();
  final cleanDistrict = district.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final cleanPincode = pincode.trim();

  // 1. Any Delhi address or 110xxx pincode
  if (cleanState.contains('delhi') || cleanPincode.startsWith('110')) {
    return true;
  }

  // 2. Haryana NCR Districts
  final haryanaNcr = [
    'gurgaon',
    'gurugram',
    'faridabad',
    'sonipat',
    'sonepat',
    'jhajjar',
    'bahadurgarh',
    'rohtak',
    'panipat',
    'palwal',
    'rewari',
    'nuh',
    'mewat',
    'bhiwani',
    'charkhidadri',
    'mahendragarh',
    'narnaul',
    'jind',
    'karnal',
  ];
  if (cleanState.contains('haryana') || cleanState.isEmpty) {
    for (final d in haryanaNcr) {
      if (cleanDistrict.contains(d)) return true;
    }
  }

  // 3. Uttar Pradesh NCR Districts
  final upNcr = [
    'gautambuddhanagar',
    'gautambudhnagar',
    'noida',
    'greaternoida',
    'ghaziabad',
    'meerut',
    'hapur',
    'panchsheelnagar',
    'bulandshahr',
    'bulandshahar',
    'baghpat',
    'bagpat',
    'muzaffarnagar',
    'shamli',
  ];
  if (cleanState.contains('uttar') || cleanState.contains('up') || cleanState.isEmpty) {
    for (final d in upNcr) {
      if (cleanDistrict.contains(d)) return true;
    }
  }

  // 4. Rajasthan NCR Districts
  final rajNcr = ['alwar', 'bharatpur'];
  if (cleanState.contains('rajasthan') || cleanState.isEmpty) {
    for (final d in rajNcr) {
      if (cleanDistrict.contains(d)) return true;
    }
  }

  // General district match regardless of state field spelling
  final allNcrDistricts = [...haryanaNcr, ...upNcr, ...rajNcr];
  for (final d in allNcrDistricts) {
    if (cleanDistrict.contains(d)) return true;
  }

  return false;
}
