import 'package:flutter/material.dart';
import 'package:hero/data/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  size: 30,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (category.description != null)
                Text(
                  category.description!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    if (lowerName.contains('mass') || lowerName.contains('gain')) {
      return Icons.monitor_weight;
    } else if (lowerName.contains('protein') || lowerName.contains('whey')) {
      return Icons.sports_gymnastics;
    } else if (lowerName.contains('creatine')) {
      return Icons.energy_savings_leaf;
    } else if (lowerName.contains('fat') || lowerName.contains('burn')) {
      return Icons.fireplace;
    } else if (lowerName.contains('vitamin') || lowerName.contains('supplement')) {
      return Icons.health_and_safety;
    } else if (lowerName.contains('accessory') || lowerName.contains('equipment')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('pre-workout')) {
      return Icons.bolt;
    } else if (lowerName.contains('amino') || lowerName.contains('eaa')) {
      return Icons.science;
    }

    return Icons.category;
  }
}