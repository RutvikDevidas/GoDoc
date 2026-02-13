import '../models/doctor.dart';
import '../models/specialization.dart';

class DemoData {
  static const specializations = <Specialization>[
    Specialization(id: "dentist", name: "Odontology", icon: "🦷"),
    Specialization(id: "neuro", name: "Neurology", icon: "🧠"),
    Specialization(id: "cardio", name: "Cardiology", icon: "❤️"),
    Specialization(id: "derma", name: "Dermatology", icon: "🧴"),
    Specialization(id: "pedia", name: "Pediatrics", icon: "👶"),
    Specialization(id: "uro", name: "Urology", icon: "🧬"),
  ];

  static const doctors = <Doctor>[
    Doctor(
      id: "d1",
      name: "Dr. Hamza Tariq",
      title: "Senior Surgeon",
      specializationId: "cardio",
      rating: 4.9,
      reviews: 96,
      imageUrl:
          "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=800",
      hospital: "Mirpur Medical College and Hospital",
      about:
          "Patient-focused specialist with clear guidance and safe treatment plans.",
      address: "Mirpur, Dhaka",
    ),
    Doctor(
      id: "d2",
      name: "Dr. Alina Fatima",
      title: "Neurologist",
      specializationId: "neuro",
      rating: 5.0,
      reviews: 120,
      imageUrl:
          "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=800",
      hospital: "City Care Hospital",
      about: "Focused on neurological consultations and long-term care plans.",
      address: "City Center Road",
    ),
    Doctor(
      id: "d3",
      name: "Dr. Ali Uzair",
      title: "Cardiologist",
      specializationId: "cardio",
      rating: 4.9,
      reviews: 96,
      imageUrl:
          "https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=800",
      hospital: "Crist Hospital, London, UK",
      about:
          "Cardiologist known for accurate diagnosis and patient-friendly guidance.",
      address: "Crist Hospital, London",
    ),
  ];

  static List<Doctor> doctorsBySpec(String specId) =>
      doctors.where((d) => d.specializationId == specId).toList();
}
