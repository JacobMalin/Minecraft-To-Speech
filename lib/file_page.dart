import 'package:flutter/material.dart';

class FilePage extends StatelessWidget {
  const FilePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Placeholder(),
        ),
        Expanded(
          child: Placeholder(),
        ),
      ],
    );
  }
}
