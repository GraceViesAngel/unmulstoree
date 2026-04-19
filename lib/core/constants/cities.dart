class CityData {
  final String name;
  final int zone;
  final int shippingCost;

  const CityData({
    required this.name,
    required this.zone,
    required this.shippingCost,
  });
}

class Cities {
  static const List<CityData> all = [
    CityData(name: 'Kota Samarinda', zone: 1, shippingCost: 10000),
    CityData(name: 'Kota Bontang', zone: 1, shippingCost: 10000),
    CityData(name: 'Kota Balikpapan', zone: 1, shippingCost: 10000),
    CityData(name: 'Kabupaten Kutai Kartanegara', zone: 2, shippingCost: 15000),
    CityData(name: 'Kabupaten Kutai Timur', zone: 2, shippingCost: 15000),
    CityData(name: 'Kabupaten Penajam Paser Utara', zone: 2, shippingCost: 15000),
    CityData(name: 'Kabupaten Kutai Barat', zone: 2, shippingCost: 15000),
    CityData(name: 'Kabupaten Paser', zone: 2, shippingCost: 15000),
  ];

  static List<String> get names => all.map((c) => c.name).toList();

  static CityData? getByName(String name) {
    try {
      return all.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  static int getShippingCost(String? cityName) {
    final city = getByName(cityName ?? '');
    return city?.shippingCost ?? 0;
  }
}