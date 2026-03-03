import 'package:flutter/material.dart';
import 'package:hero/data/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final int? productCount;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.productCount,
  });

  Color _getCategoryColor(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    if (lowerName.contains('mass') || lowerName.contains('gain')) return const Color(0xFFFF9800);
    if (lowerName.contains('protein') || lowerName.contains('whey')) return const Color(0xFF2196F3);
    if (lowerName.contains('creatine')) return const Color(0xFF9C27B0);
    if (lowerName.contains('fat') || lowerName.contains('burn')) return const Color(0xFFF44336);
    if (lowerName.contains('vitamin') || lowerName.contains('supplement') || lowerName.contains('nutritional')) return const Color(0xFF4CAF50);
    if (lowerName.contains('accessory') || lowerName.contains('accessories') || lowerName.contains('equipment')) return const Color(0xFF795548);
    if (lowerName.contains('pre-workout')) return const Color(0xFFFF5722);
    if (lowerName.contains('amino') || lowerName.contains('eaa')) return const Color(0xFF00BCD4);
    return const Color(0xFF3B82F6);
  }

  IconData _getCategoryIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    if (lowerName.contains('mass') || lowerName.contains('gain')) return Icons.monitor_weight;
    if (lowerName.contains('protein') || lowerName.contains('whey')) return Icons.fitness_center;
    if (lowerName.contains('creatine')) return Icons.bolt;
    if (lowerName.contains('fat') || lowerName.contains('burn')) return Icons.local_fire_department;
    if (lowerName.contains('vitamin') || lowerName.contains('supplement') || lowerName.contains('nutritional')) return Icons.health_and_safety;
    if (lowerName.contains('accessory') || lowerName.contains('accessories') || lowerName.contains('equipment')) return Icons.sports;
    if (lowerName.contains('pre-workout')) return Icons.energy_savings_leaf;
    if (lowerName.contains('amino') || lowerName.contains('eaa')) return Icons.science;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(category.name);
    final icon = _getCategoryIcon(category.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withOpacity(0.15),
              categoryColor.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: categoryColor.withOpacity(0.2)),
        ),
        child: Stack(
          children: [
            // Background watermark
            Positioned(
              right: -4,
              bottom: -4,
              child: Opacity(
                opacity: 0.05,
                child: Icon(icon, size: 80, color: categoryColor),
              ),
            ),

            // Corner arrow
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Icon(Icons.arrow_forward_ios, size: 14, color: categoryColor),
              ),
            ),

            // Main content — NO Spacer, uses mainAxisSize.min
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // ← THE FIX
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, size: 26, color: categoryColor),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Description
                  if (category.description != null)
                    Text(
                      category.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Product count badge
                  if (productCount != null && productCount! > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 11, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            '$productCount products',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}