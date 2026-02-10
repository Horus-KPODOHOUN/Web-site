import 'package:flutter/material.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'name': 'Tout',
      'icon': Icons.apps,
      'color': const Color(0xFF4A148C),
    },
    {
      'id': 'menstruation',
      'name': 'Menstruation',
      'icon': Icons.water_drop,
      'color': const Color(0xFFE91E63),
    },
    {
      'id': 'nutrition',
      'name': 'Nutrition',
      'icon': Icons.restaurant,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': 'ist',
      'name': 'IST & Contraception',
      'icon': Icons.health_and_safety,
      'color': const Color(0xFF2196F3),
    },
    {
      'id': 'sexuality',
      'name': 'Sexualité',
      'icon': Icons.favorite,
      'color': const Color(0xFFFF6B9D),
    },
    {
      'id': 'vbg',
      'name': 'VBG',
      'icon': Icons.shield,
      'color': const Color(0xFFF44336),
    },
  ];

  final List<Map<String, dynamic>> _contents = [
    {
      'category': 'menstruation',
      'title': 'Comprendre le cycle menstruel',
      'description':
          'Les différentes phases et ce qui se passe dans votre corps',
      'duration': '8 min',
      'type': 'audio',
      'image': 'https://via.placeholder.com/300x150/E91E63/FFFFFF?text=Cycle',
      'popular': true,
    },
    {
      'category': 'menstruation',
      'title': 'Gérer les douleurs menstruelles',
      'description': 'Conseils pratiques et remèdes naturels',
      'duration': '6 min',
      'type': 'video',
      'image':
          'https://via.placeholder.com/300x150/FF6B9D/FFFFFF?text=Douleurs',
      'popular': true,
    },
    {
      'category': 'menstruation',
      'title': 'Hygiène pendant les règles',
      'description': 'Bonnes pratiques et produits recommandés',
      'duration': '5 min',
      'type': 'audio',
      'image': 'https://via.placeholder.com/300x150/4A148C/FFFFFF?text=Hygiène',
      'popular': false,
    },
    {
      'category': 'nutrition',
      'title': 'Alimentation et cycle menstruel',
      'description': 'Quoi manger selon la phase de votre cycle',
      'duration': '10 min',
      'type': 'audio',
      'image':
          'https://via.placeholder.com/300x150/4CAF50/FFFFFF?text=Nutrition',
      'popular': true,
    },
    {
      'category': 'nutrition',
      'title': 'Aliments qui réduisent les crampes',
      'description': 'Liste des aliments anti-inflammatoires',
      'duration': '7 min',
      'type': 'video',
      'image':
          'https://via.placeholder.com/300x150/8BC34A/FFFFFF?text=Anti-crampes',
      'popular': false,
    },
    {
      'category': 'ist',
      'title': 'Prévention des IST',
      'description': 'Comment se protéger efficacement',
      'duration': '12 min',
      'type': 'audio',
      'image': 'https://via.placeholder.com/300x150/2196F3/FFFFFF?text=IST',
      'popular': true,
    },
    {
      'category': 'ist',
      'title': 'Les méthodes contraceptives',
      'description': 'Comparaison et efficacité de chaque méthode',
      'duration': '15 min',
      'type': 'video',
      'image':
          'https://via.placeholder.com/300x150/03A9F4/FFFFFF?text=Contraception',
      'popular': true,
    },
    {
      'category': 'sexuality',
      'title': 'Sexualité épanouie et saine',
      'description': 'Communication et consentement dans le couple',
      'duration': '9 min',
      'type': 'audio',
      'image':
          'https://via.placeholder.com/300x150/FF6B9D/FFFFFF?text=Sexualité',
      'popular': false,
    },
    {
      'category': 'sexuality',
      'title': 'Connaître son corps',
      'description': 'Anatomie féminine expliquée simplement',
      'duration': '11 min',
      'type': 'video',
      'image':
          'https://via.placeholder.com/300x150/E91E63/FFFFFF?text=Anatomie',
      'popular': true,
    },
    {
      'category': 'vbg',
      'title': 'Reconnaître les violences',
      'description': 'Types de violences et signes d\'alerte',
      'duration': '10 min',
      'type': 'audio',
      'image': 'https://via.placeholder.com/300x150/F44336/FFFFFF?text=VBG',
      'popular': false,
    },
    {
      'category': 'vbg',
      'title': 'Que faire en cas de violence',
      'description': 'Ressources et numéros d\'urgence',
      'duration': '8 min',
      'type': 'audio',
      'image': 'https://via.placeholder.com/300x150/E53935/FFFFFF?text=Aide',
      'popular': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredContents {
    if (_selectedCategory == 'all') return _contents;
    return _contents.where((c) => c['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildCategories(),
            _buildPopularSection(),
            _buildContentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.school, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Éducation & Conseils',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Apprends et prends soin de toi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF4A148C)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rechercher un sujet...',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: Container(
        height: 110,
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['id'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'];
                });
              },
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  category['color'],
                                  (category['color'] as Color).withOpacity(0.7)
                                ],
                              )
                            : null,
                        color: !isSelected
                            ? (category['color'] as Color).withOpacity(0.1)
                            : null,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (category['color'] as Color)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: isSelected ? Colors.white : category['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF4A148C)
                            : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPopularSection() {
    final popularContents =
        _contents.where((c) => c['popular'] == true).toList();

    if (_selectedCategory != 'all')
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Color(0xFFE91E63), size: 20),
                SizedBox(width: 8),
                Text(
                  'Populaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: popularContents.length,
                itemBuilder: (context, index) {
                  return _buildPopularCard(popularContents[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCard(Map<String, dynamic> content) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 120,
                  color: _getCategoryColor(content['category']),
                  child: Center(
                    child: Icon(
                      content['type'] == 'audio'
                          ? Icons.headphones
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        content['duration'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  content['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentsList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.library_books,
                        color: Color(0xFF4A148C), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory == 'all'
                          ? 'Tous les contenus'
                          : 'Contenus',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A148C),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredContents.length} articles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final content = _filteredContents[index - 1];
            return _buildContentCard(content);
          },
          childCount: _filteredContents.length + 1,
        ),
      ),
    );
  }

  Widget _buildContentCard(Map<String, dynamic> content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showContentDetails(content);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color:
                        _getCategoryColor(content['category']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    content['type'] == 'audio'
                        ? Icons.headphones
                        : Icons.play_circle_filled,
                    color: _getCategoryColor(content['category']),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A148C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            content['duration'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(content['category'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getCategoryName(content['category']),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(content['category']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContentDetails(Map<String, dynamic> content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(content['category']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(
                            content['type'] == 'audio'
                                ? Icons.headphones
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        content['title'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A148C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(content['category'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: _getCategoryColor(content['category']),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  content['duration'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _getCategoryColor(content['category']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  content['type'] == 'audio'
                                      ? Icons.headphones
                                      : Icons.videocam,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  content['type'] == 'audio'
                                      ? 'Audio'
                                      : 'Vidéo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        content['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _getCategoryColor(content['category']),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                content['type'] == 'audio'
                                    ? Icons.play_arrow
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Commencer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'menstruation':
        return const Color(0xFFE91E63);
      case 'nutrition':
        return const Color(0xFF4CAF50);
      case 'ist':
        return const Color(0xFF2196F3);
      case 'sexuality':
        return const Color(0xFFFF6B9D);
      case 'vbg':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF4A148C);
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'menstruation':
        return 'Menstruation';
      case 'nutrition':
        return 'Nutrition';
      case 'ist':
        return 'IST';
      case 'sexuality':
        return 'Sexualité';
      case 'vbg':
        return 'VBG';
      default:
        return 'Autre';
    }
  }
}
