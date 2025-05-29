import 'dart:async';
import 'dart:math';

import 'auth_service.dart';

class FriendRequestPollingService {
  final _controller = StreamController<Map<String, List<Map<String, dynamic>>>>.broadcast();
  Timer? _timer;

  Stream<Map<String, List<Map<String, dynamic>>>> get stream => _controller.stream;

  void startPolling() {
    _scheduleNext();
  }

  void _scheduleNext() {
    final delay = Duration(seconds: 10 + Random().nextInt(6)); // 10–15 sec
    _timer = Timer(delay, () async {
      try {
        final incoming = await AuthService().getIncomingFriendRequests();
        final outgoing = await AuthService().getOutgoingFriendRequests();
        final friendlist = await AuthService().getFriendsList();

        _controller.add({
          'incoming': incoming,
          'outgoing': outgoing,
          'friendlist': friendlist,
        });
      } catch (e) {
        print('Polling error: $e');
      } finally {
        _scheduleNext();
      }
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _controller.close();
  }
}
