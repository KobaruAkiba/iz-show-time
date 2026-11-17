import 'package:flutter/material.dart';
import '../../widgets/app_page_header.dart';
import 'catalogue_view.dart';

/// Screen displaying the user's catalogue of films and shows
class CatalogueScreen extends StatefulWidget {
  final bool isActive;

  const CatalogueScreen({super.key, this.isActive = true});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(),
            Expanded(child: CatalogueView(isActive: widget.isActive)),
          ],
        ),
      ),
    );
  }
}
