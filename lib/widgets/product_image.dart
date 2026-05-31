import 'package:flutter/material.dart';
import '../core/theme.dart';

class ProductImage extends StatelessWidget {
  final String? url;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ProductImage({super.key, required this.url, required this.size, this.borderRadius, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(10);
    final placeholder = ClipRRect(borderRadius:br,
      child:Container(width:size, height:size, color:FeezColors.off,
        child:Icon(Icons.image_outlined, color:FeezColors.line, size:size*0.4)));

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(borderRadius:br,
      child:Image.network(url!, width:size, height:size, fit:fit,
        errorBuilder:(_,__,___) => placeholder,
        loadingBuilder:(ctx,child,progress) {
          if (progress == null) return child;
          return Container(width:size, height:size, color:FeezColors.off,
            child:Center(child:SizedBox(width:size*0.3, height:size*0.3,
              child:CircularProgressIndicator(strokeWidth:1.5, color:FeezColors.line,
                value:progress.expectedTotalBytes!=null
                  ? progress.cumulativeBytesLoaded/progress.expectedTotalBytes! : null))));
        }));
  }
}
