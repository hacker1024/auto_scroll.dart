import 'package:auto_scroll/auto_scroll.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: AutoScrollerExample(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class AutoScrollerExample extends StatefulWidget {
  const AutoScrollerExample({super.key});

  @override
  State<AutoScrollerExample> createState() => _AutoScrollerExampleState();
}

class _AutoScrollerExampleState extends State<AutoScrollerExample> {
  static const _initialItemCount = 20;

  var _itemCount = _initialItemCount;
  final _controller = AutoScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Scroller'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _itemCount = _initialItemCount),
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: AutoScroller(
        controller: _controller,
        lengthIdentifier: _itemCount,
        anchorThreshold: 24,
        builder: (context, controller) {
          return ListView.builder(
            controller: controller,
            itemCount: _itemCount,
            itemBuilder: (context, index) =>
                ListTile(title: Text('Item $index')),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _controller,
            builder: (context, value, child) {
              return FloatingActionButton(
                mini: true,
                disabledElevation: 0,
                tooltip: 'Manual anchor',
                onPressed: value ? null : () => _controller.anchored = true,
                child: child,
              );
            },
            child: const Icon(Icons.anchor),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: _controller,
            builder: (context, value, child) {
              return FloatingActionButton(
                mini: true,
                disabledElevation: 0,
                tooltip: 'Go to bottom',
                onPressed: value ? null : _controller.animateToAnchor,
                child: child,
              );
            },
            child: const Icon(Icons.vertical_align_bottom),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => setState(() => ++_itemCount),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
