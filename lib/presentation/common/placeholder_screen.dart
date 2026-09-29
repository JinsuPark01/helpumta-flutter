import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaceholderLink {
  const PlaceholderLink(this.label, this.location, {this.replace = false});

  final String label;
  final String location;
  final bool replace;
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.links = const [],
  });

  final String title;
  final List<PlaceholderLink> links;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final link in links)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: FilledButton(
                  onPressed: () => link.replace
                      ? context.go(link.location)
                      : context.push(link.location),
                  child: Text(link.label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}