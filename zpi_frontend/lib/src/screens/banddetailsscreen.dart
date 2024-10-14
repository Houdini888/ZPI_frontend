import 'package:zpi_frontend/src/models/band.dart';
import 'package:flutter/material.dart';

class BandDetailsScreen extends StatelessWidget {
  final Band band;

  const BandDetailsScreen({Key? key, required this.band}) : super(key: key);

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
              title: Container(
                // padding: const EdgeInsets.all(8.0),
                // color: Colors.blueGrey,
                child: Text(
                  band.name,
                  style: TextStyle(
                    fontSize: 32.0,            // Large text size
                    fontWeight: FontWeight.bold, // Bold (thick) text
                    color: Colors.blueGrey
                  ),
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
                  // Band Name (redundant if already in AppBar, optional)
                  // Text(
                  //   band.name,
                  //   style: TextStyle(
                  //     fontSize: 24,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  SizedBox(height: 16),
                  SizedBox(height: 24),
                  // Placeholder for Future Functionalities
                  // Example: Upcoming Events, Band Members, etc.
                  // You can add widgets here as you expand functionality
                  Text(
                    'More Features Coming Soon!',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
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


