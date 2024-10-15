import 'package:zpi_frontend/src/models/band.dart';
import 'package:zpi_frontend/src/widgets/memberlist.dart';
import 'package:flutter/material.dart';

class BandDetailsScreen extends StatelessWidget {
  final Band band;

  const BandDetailsScreen({super.key, required this.band});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a CustomScrollView to allow for flexible scrolling behavior
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                band.name,
                style: const TextStyle(
                  fontSize: 32.0,            // Large text size
                  fontWeight: FontWeight.bold, // Bold (thick) text
                  color: Colors.blueGrey
                ),
              ),
              background: band.imageUrl.startsWith('http')
                  ? Image.network(
                      band.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      band.imageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Current song: TODO",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Placeholder for Future Functionalities
                  // Example: Upcoming Events, Band Members, etc.
                  // You can add widgets here as you expand functionality
                    Row(
                    children: [
                      const Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: null,
                          child: Text("Choose your piece"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 200,
                          child: Memberlist(),
                        )
                        ) 
                    ],
                  )

                  // Add more widgets here in the future
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


