class WeatherModel {
  final String city;
  final int temperatureC;
  final int temperatureF;
  final String condition;
  final int windSpeedKmH;
  final String windDirection;
  final int visibilityKm;
  final int humidity;
  final String sunriseTime;
  final String flightStatus; // favorable | uncertain | unfavorable
  final String flightSafetySummary;
  final String recommendation;

  WeatherModel({
    required this.city,
    required this.temperatureC,
    required this.temperatureF,
    required this.condition,
    required this.windSpeedKmH,
    required this.windDirection,
    required this.visibilityKm,
    required this.humidity,
    required this.sunriseTime,
    required this.flightStatus,
    required this.flightSafetySummary,
    required this.recommendation,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['city'] ?? 'Luxor',
      temperatureC: json['temperatureC'] ?? 28,
      temperatureF: json['temperatureF'] ?? 82,
      condition: json['condition'] ?? 'Sunny & Clear',
      windSpeedKmH: json['windSpeedKmH'] ?? 8,
      windDirection: json['windDirection'] ?? 'NE',
      visibilityKm: json['visibilityKm'] ?? 10,
      humidity: json['humidity'] ?? 35,
      sunriseTime: json['sunriseTime'] ?? '05:35 AM',
      flightStatus: json['flightStatus'] ?? 'favorable',
      flightSafetySummary: json['flightSafetySummary'] ?? 'Conditions look favorable for sunrise flights.',
      recommendation: json['recommendation'] ?? 'Safe to fly. Final confirmation by pilots at 04:30 AM.',
    );
  }
}
