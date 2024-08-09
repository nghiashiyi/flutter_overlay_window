import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class MessangerChatHead extends StatefulWidget {
  const MessangerChatHead({Key? key}) : super(key: key);

  @override
  State<MessangerChatHead> createState() => _MessangerChatHeadState();
}

class _MessangerChatHeadState extends State<MessangerChatHead> {
  Color color = const Color(0xFFFFFFFF);
  BoxShape _currentShape = BoxShape.circle;
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  final _receivePort = ReceivePort();
  SendPort? homePort;
  String? messageFromOverlay;
  OverlayPosition? _cacheOverlayPosition;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (homePort != null) return;
    final res = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _kPortNameOverlay,
    );
    log("$res : HOME");
    _receivePort.listen((message) {
      log("message from UI: $message");
      setState(() {
        messageFromOverlay = 'message from UI: $message';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: GestureDetector(
        onTap: () async {
          if (_isProcessing) {
            return;
          }

          print("Process start");
          _isProcessing = true;
          if (_currentShape == BoxShape.rectangle) {
            await FlutterOverlayWindow.resizeOverlay(50, 50, true);
            if (_cacheOverlayPosition != null) {
              await FlutterOverlayWindow.moveOverlay(_cacheOverlayPosition!);
              _cacheOverlayPosition = null;
            }
            await FlutterOverlayWindow.setIgnoreSnapping(false);
            setState(() {
              _currentShape = BoxShape.circle;
            });
          } else {
            await FlutterOverlayWindow.setIgnoreSnapping(true);
            _cacheOverlayPosition =
                await FlutterOverlayWindow.getOverlayPosition();
            await FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 0));
            await Future.delayed(const Duration(milliseconds: 500));
            await FlutterOverlayWindow.resizeOverlay(
              WindowSize.matchParent,
              100,
              false,
            );
            setState(() {
              _currentShape = BoxShape.rectangle;
            });
          }
          _isProcessing = false;
          print("Process done");
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: _currentShape,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _currentShape == BoxShape.rectangle
                    ? SizedBox(
                        width: 200.0,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          onPressed: () {
                            homePort ??= IsolateNameServer.lookupPortByName(
                              _kPortNameHome,
                            );
                            homePort?.send('Date: ${DateTime.now()}');
                          },
                          child: const Text("Send message to UI"),
                        ),
                      )
                    : const SizedBox.shrink(),
                _currentShape == BoxShape.rectangle
                    ? messageFromOverlay == null
                        ? const FlutterLogo()
                        : Text(messageFromOverlay ?? '')
                    : const FlutterLogo()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
