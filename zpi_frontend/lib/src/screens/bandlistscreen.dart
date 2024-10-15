import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/band.dart';
import 'package:zpi_frontend/src/screens/banddetailsscreen.dart';

import '../widgets/app_drawer_menu.dart';

class BandListScreen extends StatelessWidget {
  final List<Band> bands = [
    Band(name: "Pink Floyd", imageUrl: 'images/band_pf.jpg'),
    Band(name: "Black Sabbath", imageUrl: 'images/band_bs.jpg'),
    Band(name: "Akcent", imageUrl: 'images/band_akcent.jpg')
  ];

@override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Bands List'),
      ),
      body: ListView.builder(
        itemCount: bands.length,
        itemBuilder: (context, index) {
          final band = bands[index];
          return ListTile(
            title: Text(band.name),
            onTap: () {
              // Navigate to the BandDetailsScreen when tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BandDetailsScreen(band: band)
                  )
              );
            },
          );
        },
      ),
    );
  }

}