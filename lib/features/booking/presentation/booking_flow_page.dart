import 'package:flutter/material.dart';

class BookingFlowPage extends StatelessWidget {
  const BookingFlowPage({super.key, required this.placeId, this.eventId});
  final String placeId;
  final String? eventId;

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Booking flow — coming soon')),
  );
}
