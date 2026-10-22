import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Horizontal tray with vertical-affinity Draggable items scrolls horizontally', (tester) async {
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 140,
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 20,
              separatorBuilder: (_, __) => const SizedBox(width: 28),
              itemBuilder: (context, index) {
                return Draggable<String>(
                  data: 'piece_$index',
                  affinity: Axis.vertical,
                  feedback: const Material(child: SizedBox(width: 60, height: 60, child: Text('Dragging'))),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.blue,
                    child: Center(child: Text('P$index')),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0.0);

    // Perform horizontal drag (swipe left to scroll right)
    await tester.drag(find.text('P0'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Verify offset changed - meaning it scrolled horizontally!
    expect(scrollController.offset, greaterThan(100.0));
  });
}
