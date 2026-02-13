class Doctor {
  final String id;
  final String name;
  final String title;
  final String specializationId;
  final double rating;
  final int reviews;
  final String imageUrl;
  final String hospital;
  final String about;
  final String address;

  const Doctor({
    required this.id,
    required this.name,
    required this.title,
    required this.specializationId,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.hospital,
    required this.about,
    required this.address,
  });
}
