import '../events.dart';
import 'channel.dart';
import 'listener.dart';

/// Platforms with neither `dart:io` nor `dart:js_interop`: no networking.

Future<MessageChannel> connectTcp(Object host, int port, Duration timeout) =>
    Future.error(const NetException('no networking on this platform'));

Future<MessageChannel> connectWebSocket(Uri url, Duration timeout) =>
    Future.error(const NetException('no networking on this platform'));

Future<HostListener> bindHostListener({Object? address, required int port, int? wsPort}) =>
    Future.error(UnsupportedError('no networking on this platform'));
