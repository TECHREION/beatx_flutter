// import 'package:flutter/material.dart';

// class AudiobookBottomNav extends StatelessWidget {
//   const AudiobookBottomNav({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });

//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   static const _items = [
//     (Icons.headphones_rounded, 'Listen'),
//     (Icons.play_circle_fill_rounded, 'Watch'),
//     (Icons.mic_external_on_rounded, 'Podcast'),
//     (Icons.menu_book_rounded, 'Audiobook'),
//     (Icons.storefront_rounded, 'SHOP'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 72,
//       decoration: const BoxDecoration(
//         color: Color(0xFF202020),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
//       ),
//       child: Row(
//         children: List.generate(_items.length, (index) {
//           final item = _items[index];
//           final selected = index == currentIndex;
//           final color = selected
//               ? const Color(0xFF44E5F1)
//               : const Color(0xFF9B989F);

//           return Expanded(
//             child: InkWell(
//               onTap: () => onTap(index),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: selected ? 54 : 34,
//                     height: 34,
//                     decoration: BoxDecoration(
//                       color: selected
//                           ? const Color(0xFF0A5C68)
//                           : Colors.transparent,
//                       borderRadius: BorderRadius.circular(18),
//                     ),
//                     child: Icon(item.$1, color: color, size: 21),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     item.$2,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: color,
//                       fontSize: 12,
//                       fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
//                       letterSpacing: 0,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }
