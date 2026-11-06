/// Modelo de datos que representa una solicitud de viaje entrante.
/// Listo para mapear con Firebase Cloud Firestore o WebSockets en fases posteriores.
class RideRequestModel {
  final String id;
  final String passengerName;
  final double passengerRating;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int durationMinutes;
  final double estimatedEarnings;
  final String paymentMethod;

  const RideRequestModel({
    required this.id,
    required this.passengerName,
    required this.passengerRating,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedEarnings,
    this.paymentMethod = 'Efectivo',
  });

  /// Datos de prueba (Mock) contextualizados en la ciudad de Riobamba
  static RideRequestModel mockDemoRequest() {
    return const RideRequestModel(
      id: 'RB-MOTO-1042',
      passengerName: 'Carlos M.',
      passengerRating: 4.9,
      pickupAddress: 'ESPOCH (Puerta Principal)',
      dropoffAddress: 'Terminal Terrestre Riobamba',
      distanceKm: 2.5,
      durationMinutes: 6,
      estimatedEarnings: 1.25,
      paymentMethod: 'Efectivo',
    );
  }
}
