// import 'package:flutter/material.dart';
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

// class IncomingCallWidget extends StatefulWidget {
//   final String callerName;
//   final String callerAvatarUrl;
//   final VoidCallback onAccept;
//   final VoidCallback onDecline;

//   const IncomingCallWidget({
//     Key? key,
//     required this.callerName,
//     required this.callerAvatarUrl,
//     required this.onAccept,
//     required this.onDecline,
//   }) : super(key: key);

//   @override
//   State<IncomingCallWidget> createState() => _IncomingCallWidgetState();
// }

// class _IncomingCallWidgetState extends State<IncomingCallWidget> {
//   FlutterRingtonePlayer player = FlutterRingtonePlayer();
//   @override
//   void initState() {
//     super.initState();
//     player.playRingtone();
//   }

//   @override
//   void dispose() {
//     player.stop();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black.withOpacity(0.8),
//       body: Center(
//         child: Container(
//           padding: const EdgeInsets.all(32),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 16,
//                 offset: Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircleAvatar(
//                 radius: 48,
//                 backgroundImage: NetworkImage(widget.callerAvatarUrl),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 widget.callerName,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Incoming Call...',
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 32),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   FloatingActionButton(
//                     heroTag: 'decline',
//                     backgroundColor: Colors.red,
//                     onPressed: widget.onDecline,
//                     child: const Icon(Icons.call_end, color: Colors.white),
//                   ),
//                   FloatingActionButton(
//                     heroTag: 'accept',
//                     backgroundColor: Colors.green,
//                     onPressed: widget.onAccept,
//                     child: const Icon(Icons.call, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
