import 'package:flutter/material.dart';

class CustomCategoryScreen extends StatelessWidget {
  // These variables allow the screen to change based on what you tapped
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;

  const CustomCategoryScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    this.categoryIcon = Icons.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Dynamic Header with Gradient and Icon
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true, // Keeps the title visible when scrolling
            backgroundColor: categoryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      categoryColor,
                      categoryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Icon(
                  categoryIcon,
                  size: 100,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),

          // 2. The Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Available Items",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("View All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. Dynamic List of Items
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 8, // Replace with your actual data list length
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(categoryIcon, color: categoryColor),
                          ),
                          title: Text(
                            "$categoryName Item ${index + 1}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text("High quality product description..."),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to Product Detail Screen here
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}