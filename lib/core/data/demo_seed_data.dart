import '../../models/admin_model.dart';
import '../../models/doctor_model.dart';

class DemoSeedData {
  DemoSeedData._();

  static const AdminModel defaultAdmin = AdminModel(
    username: 'admin',
    password: 'admin',
    name: 'GoDoc Admin',
    email: 'admin@godoc.app',
  );

  static final DateTime _today = DateTime.now();

  static DateTime get _baseDate => DateTime(
    _today.year,
    _today.month,
    _today.day,
  );

  static final DoctorModel demoDoctor = DoctorModel(
    username: 'demo_doctor',
    password: 'demo123',
    name: 'Dr. Aarav Mehta',
    dob: '14/8/1985',
    prNumber: 'PR-DEL-4582',
    nmcNumber: 'NMC/2020/11834',
    licenceNumber: 'LIC-MED-7741',
    specialization: 'Cardiologist',
    phone: '9876543210',
    clinicName: 'GoDoc Heart & Wellness Clinic',
    clinicAddress: '12 Residency Road, Bengaluru, Karnataka',
    clinicLocation: '12.9716, 77.5946',
    clinicLatitude: 12.9716,
    clinicLongitude: 77.5946,
    bio:
        'Dr. Aarav Mehta is an experienced cardiologist focused on preventive heart care, lifestyle guidance, and clear long-term treatment plans.',
    upiId: 'demo_doctor@upi',
    bankAccountHolder: 'Dr Aarav Mehta',
    bankName: 'State Bank of India',
    bankAccountNumber: '123456789012',
    bankIfscCode: 'SBIN0000456',
    consultationFee: 750,
    availability: [
      DoctorAvailability(
        date: _baseDate.add(const Duration(days: 1)),
        timeSlots: const ['10:00 AM', '11:30 AM', '04:00 PM'],
      ),
      DoctorAvailability(
        date: _baseDate.add(const Duration(days: 2)),
        timeSlots: const ['09:30 AM', '01:00 PM', '05:30 PM'],
      ),
      DoctorAvailability(
        date: _baseDate.add(const Duration(days: 4)),
        timeSlots: const ['10:15 AM', '12:45 PM', '03:15 PM'],
      ),
    ],
    verified: true,
    rejected: false,
  );

  static List<DoctorModel> get initialDoctors => [demoDoctor];
}
