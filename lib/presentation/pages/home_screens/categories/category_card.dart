import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    // Color palette for categories
    if (lowerName.contains('mass') || lowerName.contains('gain')) {
      return const Color(0xFFFF9800); // Orange
    } else if (lowerName.contains('protein') || lowerName.contains('whey')) {
      return const Color(0xFF2196F3); // Blue
    } else if (lowerName.contains('creatine')) {
      return const Color(0xFF9C27B0); // Purple
    } else if (lowerName.contains('fat') || lowerName.contains('burn')) {
      return const Color(0xFFF44336); // Red
    } else if (lowerName.contains('vitamin') || lowerName.contains('supplement')) {
      return const Color(0xFF4CAF50); // Green
    } else if (lowerName.contains('accessory') || lowerName.contains('equipment')) {
      return const Color(0xFF795548); // Brown
    } else if (lowerName.contains('pre-workout')) {
      return const Color(0xFFFF5722); // Deep Orange
    } else if (lowerName.contains('amino') || lowerName.contains('eaa')) {
      return const Color(0xFF00BCD4); // Cyan
    }

    return const Color(0xFF3B82F6); // Default blue
  }

  IconData _getCategoryIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    if (lowerName.contains('mass') || lowerName.contains('gain')) {
      return Icons.monitor_weight;
    } else if (lowerName.contains('protein') || lowerName.contains('whey')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('creatine')) {
      return Icons.bolt;
    } else if (lowerName.contains('fat') || lowerName.contains('burn')) {
      return Icons.fireplace;
    } else if (lowerName.contains('vitamin') || lowerName.contains('supplement')) {
      return Icons.health_and_safety;
    } else if (lowerName.contains('accessory') || lowerName.contains('equipment')) {
      return Icons.sports;
    } else if (lowerName.contains('pre-workout')) {
      return Icons.energy_savings_leaf;
    } else if (lowerName.contains('amino') || lowerName.contains('eaa')) {
      return Icons.science;
    }

    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(category.name);
    final icon = _getCategoryIcon(category.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
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
          border: Border.all(
            color: categoryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  icon,
                  size: 80,
                  color: categoryColor,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 28,
                        color: categoryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Name
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Description (if available)
                  if (category.description != null)
                    Text(
                      category.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const Spacer(),

                  // Product Count Badge
                  if (productCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: categoryColor,
                          ),
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
              ),
            ),

            // Corner decoration
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: categoryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}