import 'package:armazem/pages/movements/movements_page.dart';
import 'package:armazem/pages/products/products_page.dart';
import 'package:flutter/material.dart';
import 'categories/categories_page.dart';

class ArmazemPage extends StatelessWidget {
  const ArmazemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isWideScreen ? 80.0 : 32.0),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Image.asset(
                  'assets/images/logo_image.png',
                  width: isWideScreen ? 300 : 200,
                  height: isWideScreen ? 300 : 200,
                ),
                Text(
                  'Almoxarifado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWideScreen ? 45 : 35,
                    fontFamily: 'Anta',
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(247, 192, 118, 1),
                  ),
                ),
                const SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.orange),
                        Text(
                          'Ações rápidas:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                isWideScreen
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildMenuCard(
                              context,
                              icon: Icons.inventory_2,
                              title: 'Produto',
                              color: Colors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProductsPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMenuCard(
                              context,
                              icon: Icons.category,
                              title: 'Categoria',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CategoriesPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMenuCard(
                              context,
                              icon: Icons.move_down,
                              title: 'Movimentações',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MovementsPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _buildMenuCard(
                              context,
                              icon: Icons.inventory_2,
                              title: 'Produto',
                              color: Colors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProductsPage(),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: _buildMenuCard(
                              context,
                              icon: Icons.category,
                              title: 'Categoria',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CategoriesPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: _buildMenuCard(
                              context,
                              icon: Icons.move_down,
                              title: 'Movimentações',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MovementsPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isWideScreen ? 48 : 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWideScreen ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
