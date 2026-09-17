/// TypeORM serialises Postgres `decimal` columns as JSON *strings*
/// (e.g. "18000.00"). Calling .toDouble() or NumberFormat.format() on those
/// throws at runtime, so every money field must go through this helper.
double asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
