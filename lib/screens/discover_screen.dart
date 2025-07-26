import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/tts_service.dart';
import '../services/firebase_service.dart';
import '../services/dependency_injection.dart';
import '../models/tour_model.dart';
import '../core/routes.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/voice_status_widget.dart';
import '../widgets/tour_card_widget.dart';
import '../widgets/search_bar_widget.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TTSService _ttsService = getIt<TTSService>();
  final FirebaseService _firebaseService = getIt<FirebaseService>();

  List<TourModel> _tours = [];
  List<TourModel> _filteredTours = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _currentTourIndex = 0;

  final List<String> _categories = [
    'All',
    'Historical',
    'Nature',
    'Cultural',
    'Adventure',
    'Educational',
    'Royal',
    'Spiritual',
  ];

  // Buganda, Uganda specific tour places
  final List<Map<String, dynamic>> _bugandaTours = [
    {
      'id': 'kasubi_tombs',
      'title': 'Kasubi Tombs',
      'description':
          'The royal burial grounds of the Kabakas of Buganda, a UNESCO World Heritage site featuring traditional architecture and rich cultural history.',
      'duration': '2 hours',
      'distance': '5 km from Kampala',
      'accessibility': 'Wheelchair accessible paths, audio guides available',
      'highlights':
          'Royal tombs, traditional architecture, cultural ceremonies',
      'category': 'Historical',
      'tags': ['historical', 'royal', 'cultural'],
      'audioDescription':
          'Kasubi Tombs is the sacred burial site of the Kabakas of Buganda. The main building, Muzibu Azaala Mpanga, is a masterpiece of traditional architecture with its thatched roof and wooden structure. The site holds deep spiritual significance and showcases the rich cultural heritage of the Buganda kingdom.',
      'voiceCommands': [
        'describe kasubi tombs',
        'tell me about the royal tombs',
        'what is the history of kasubi',
      ],
    },
    {
      'id': 'namugongo_martyrs',
      'title': 'Namugongo Martyrs Shrine',
      'description':
          'A major pilgrimage site commemorating the 22 Catholic and 23 Anglican martyrs who were executed for their faith in 1886.',
      'duration': '3 hours',
      'distance': '12 km from Kampala',
      'accessibility': 'Paved walkways, audio tours, braille information',
      'highlights': 'Martyrdom site, religious significance, annual pilgrimage',
      'category': 'Spiritual',
      'tags': ['spiritual', 'historical', 'religious'],
      'audioDescription':
          'Namugongo Martyrs Shrine is a sacred site where 45 young men were martyred for their Christian faith. The shrine features beautiful architecture, peaceful gardens, and a museum that tells the story of their sacrifice. The annual pilgrimage on June 3rd attracts thousands of believers.',
      'voiceCommands': [
        'tell me about the martyrs',
        'describe namugongo shrine',
        'what happened at namugongo',
      ],
    },
    {
      'id': 'lubiri_palace',
      'title': 'Lubiri Palace',
      'description':
          'The official residence of the Kabaka of Buganda, featuring traditional and modern architecture with beautiful gardens.',
      'duration': '1.5 hours',
      'distance': '3 km from Kampala',
      'accessibility': 'Guided tours, audio descriptions, accessible entrances',
      'highlights':
          'Royal residence, traditional architecture, cultural significance',
      'category': 'Royal',
      'tags': ['royal', 'cultural', 'historical'],
      'audioDescription':
          'Lubiri Palace is the magnificent residence of the Kabaka of Buganda. The palace combines traditional African architecture with modern amenities. The surrounding gardens are meticulously maintained and the palace serves as a symbol of the enduring Buganda monarchy.',
      'voiceCommands': [
        'describe the palace',
        'tell me about the kabaka',
        'what is lubiri palace',
      ],
    },
    {
      'id': 'mengo_hill',
      'title': 'Mengo Hill',
      'description':
          'The traditional seat of the Buganda kingdom, offering panoramic views of Kampala and historical significance.',
      'duration': '2 hours',
      'distance': '2 km from Kampala',
      'accessibility': 'Walking paths, viewpoints, guided tours',
      'highlights':
          'Panoramic views, historical significance, cultural heritage',
      'category': 'Historical',
      'tags': ['historical', 'royal', 'cultural'],
      'audioDescription':
          'Mengo Hill is the traditional heart of the Buganda kingdom, offering breathtaking panoramic views of Kampala city. The hill has been the seat of Buganda power for centuries and is surrounded by important cultural and historical sites.',
      'voiceCommands': [
        'describe mengo hill',
        'tell me about the views',
        'what is the history of mengo',
      ],
    },
    {
      'id': 'bulange_parliament',
      'title': 'Bulange Parliament',
      'description':
          'The parliament building of the Buganda kingdom, showcasing traditional architecture and democratic governance.',
      'duration': '1 hour',
      'distance': '2.5 km from Kampala',
      'accessibility': 'Public tours, audio guides, accessible facilities',
      'highlights': 'Traditional parliament, cultural governance, architecture',
      'category': 'Cultural',
      'tags': ['cultural', 'historical', 'royal'],
      'audioDescription':
          'Bulange Parliament is where the Buganda kingdom\'s traditional parliament meets. The building features distinctive traditional architecture and represents the democratic traditions of the Buganda people.',
      'voiceCommands': [
        'describe bulange',
        'tell me about the parliament',
        'what is bulange building',
      ],
    },
    {
      'id': 'lake_victoria_shore',
      'title': 'Lake Victoria Shore',
      'description':
          'Explore the shores of Africa\'s largest lake, offering fishing villages, boat tours, and beautiful sunsets.',
      'duration': '4 hours',
      'distance': '8 km from Kampala',
      'accessibility': 'Beach access, boat tours, fishing experiences',
      'highlights': 'Lake views, fishing villages, boat tours, sunsets',
      'category': 'Nature',
      'tags': ['nature', 'adventure', 'cultural'],
      'audioDescription':
          'Lake Victoria, Africa\'s largest lake, offers stunning views and rich cultural experiences. Visit fishing villages, take boat tours, and enjoy spectacular sunsets over the water. The lake is central to the region\'s economy and culture.',
      'voiceCommands': [
        'describe lake victoria',
        'tell me about the lake',
        'what can i do at the lake',
      ],
    },
    {
      'id': 'ndere_centre',
      'title': 'Ndere Cultural Centre',
      'description':
          'A vibrant cultural center showcasing traditional music, dance, and performing arts from across Uganda.',
      'duration': '3 hours',
      'distance': '6 km from Kampala',
      'accessibility':
          'Performance venues, cultural workshops, audio descriptions',
      'highlights': 'Traditional music, dance performances, cultural workshops',
      'category': 'Cultural',
      'tags': ['cultural', 'educational', 'entertainment'],
      'audioDescription':
          'Ndere Cultural Centre is a vibrant hub of Ugandan culture, featuring traditional music, dance performances, and cultural workshops. Experience the rich diversity of Uganda\'s ethnic groups through their music and dance traditions.',
      'voiceCommands': [
        'describe ndere centre',
        'tell me about the performances',
        'what cultural activities are available',
      ],
    },
    {
      'id': 'kampala_markets',
      'title': 'Kampala Markets Tour',
      'description':
          'Explore the bustling markets of Kampala, including Owino Market, for authentic local experiences and traditional crafts.',
      'duration': '2.5 hours',
      'distance': '1 km from city center',
      'accessibility': 'Market tours, guided experiences, cultural immersion',
      'highlights':
          'Local markets, traditional crafts, street food, cultural immersion',
      'category': 'Cultural',
      'tags': ['cultural', 'adventure', 'educational'],
      'audioDescription':
          'Kampala\'s markets are a sensory feast of colors, sounds, and smells. From the bustling Owino Market to craft markets, experience authentic Ugandan life, traditional crafts, and delicious street food.',
      'voiceCommands': [
        'describe the markets',
        'tell me about owino market',
        'what can i buy at the markets',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
      // Update voice navigation context
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.updateCurrentScreen('discover');
    });
  }

  Future<void> _describeSpecificTour(String tourId) async {
    final tour = _bugandaTours.firstWhere(
      (t) => t['id'] == tourId,
      orElse: () => _bugandaTours.first,
    );

    await _ttsService.speak('''
${tour['title']}. ${tour['audioDescription']}
Duration: ${tour['duration']}. Distance: ${tour['distance']}.
Accessibility: ${tour['accessibility']}.
Highlights: ${tour['highlights']}.
''');
  }

  Future<void> _navigateToNextTour() async {
    if (!mounted) return;
    if (_filteredTours.isNotEmpty) {
      setState(() {
        _currentTourIndex = (_currentTourIndex + 1) % _filteredTours.length;
      });
      await _speakCurrentTour();
    }
  }

  Future<void> _navigateToPreviousTour() async {
    if (!mounted) return;
    if (_filteredTours.isNotEmpty) {
      setState(() {
        _currentTourIndex = _currentTourIndex > 0
            ? _currentTourIndex - 1
            : _filteredTours.length - 1;
      });
      await _speakCurrentTour();
    }
  }

  Future<void> _navigateToFirstTour() async {
    if (!mounted) return;
    if (_filteredTours.isNotEmpty) {
      setState(() {
        _currentTourIndex = 0;
      });
      await _speakCurrentTour();
    }
  }

  Future<void> _navigateToLastTour() async {
    if (!mounted) return;
    if (_filteredTours.isNotEmpty) {
      setState(() {
        _currentTourIndex = _filteredTours.length - 1;
      });
      await _speakCurrentTour();
    }
  }

  Future<void> _speakCurrentTour() async {
    if (_filteredTours.isNotEmpty) {
      final tour = _filteredTours[_currentTourIndex];
      await _ttsService.speak('''
Currently viewing tour ${_currentTourIndex + 1} of ${_filteredTours.length}: ${tour.title}.
${tour.description}
''');
    }
  }

  Future<void> _speakTourCount() async {
    await _ttsService.speak(
      'There are ${_filteredTours.length} tours available in the current category.',
    );
  }

  Future<void> _speakHelpCommands() async {
    await _ttsService.speak('''
Available voice commands for discover screen:
Categories: "Show historical tours", "Show cultural tours", "Show nature tours", "Show royal tours", "Show spiritual tours"
Tour navigation: "Next tour", "Previous tour", "First tour", "Last tour"
Tour information: "Describe Kasubi Tombs", "Tell me about Namugongo", "What is Lubiri Palace"
General: "Tour count", "Current tour", "Accessibility info", "Help commands"
''');
  }

  Future<void> _speakAccessibilityInfo() async {
    await _ttsService.speak('''
Accessibility features for Buganda tours:
All major sites offer audio guides and guided tours.
Wheelchair accessible paths are available at most locations.
Braille information is provided at key sites.
Trained guides are available for visitors with visual impairments.
Assistance animals are welcome at all locations.
''');
  }

  double _parseDuration(String duration) {
    // Parse duration string like "2 hours" to minutes
    if (duration.contains('hour')) {
      final hours = double.tryParse(duration.split(' ').first) ?? 1.0;
      return hours * 60;
    } else if (duration.contains('minute')) {
      return double.tryParse(duration.split(' ').first) ?? 30.0;
    }
    return 60.0; // Default to 1 hour
  }

  Future<void> _initializeScreen() async {
    await _ttsService.speakWithPriority(
      'Discover Buganda tours loaded. Voice navigation active. ${_bugandaTours.length} destinations available including royal palaces, sacred sites, and cultural centers. Say "show historical tours", "describe Kasubi Tombs", or "help commands" for options.',
    );

    await _loadTours();

    // No automatic transition for main screens - user can navigate manually
  }

  Future<void> _loadTours() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Load tours from Firebase and combine with local Buganda tours
      final firebaseTours = await _firebaseService.getTours();

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // Convert local Buganda tours to TourModel format
      final bugandaTourModels = _bugandaTours
          .map(
            (tourData) => TourModel(
              id: tourData['id'],
              title: tourData['title'],
              description: tourData['description'],
              imageUrl: 'assets/images/buganda_placeholder.jpg',
              audioFiles: [],
              points: [],
              duration: _parseDuration(tourData['duration']),
              difficulty: 'Easy',
              tags: List<String>.from(tourData['tags']),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              distance: tourData['distance'],
              accessibility: tourData['accessibility'],
              highlights: tourData['highlights'],
              category: tourData['category'],
              audioDescription: tourData['audioDescription'],
              voiceCommands: List<String>.from(tourData['voiceCommands']),
            ),
          )
          .toList();

      // Combine Firebase tours with Buganda tours
      final allTours = [...firebaseTours, ...bugandaTourModels];

      if (!mounted) return;
      setState(() {
        _tours = allTours;
        _filteredTours = allTours;
        _isLoading = false;
      });

      if (allTours.isNotEmpty) {
        await _ttsService.speakWithPriority(
          '${allTours.length} tours loaded. ${bugandaTourModels.length} Buganda destinations ready. Use voice commands like "next tour", "historical tours", or tap to explore. All tours include accessibility features.',
        );
      } else {
        await _ttsService.speakWithPriority(
          'No tours available at the moment. Please check back later.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      await _ttsService.speakWithPriority(
        'Error loading tours. Please check your connection and try again.',
      );
    }
  }

  void _filterTours() {
    if (!mounted) return;
    setState(() {
      _filteredTours = _tours.where((tour) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            tour.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tour.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (tour.audioDescription?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);

        final matchesCategory =
            _selectedCategory == 'All' ||
            (tour.category?.toLowerCase() == _selectedCategory.toLowerCase()) ||
            tour.tags.contains(_selectedCategory.toLowerCase());

        return matchesSearch && matchesCategory;
      }).toList();
    });

    _ttsService.speakWithPriority(
      '${_filteredTours.length} tours match your criteria. ${_filteredTours.isNotEmpty ? "Say 'next tour' to navigate through them." : ""}',
    );
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;
    setState(() {
      _searchQuery = query;
    });
    _filterTours();
  }

  void _onCategorySelected(String category) {
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _currentTourIndex = 0; // Reset to first tour when category changes
    });
    _filterTours();

    // Enhanced speech narration for category selection
    String categoryDescription = '';
    switch (category.toLowerCase()) {
      case 'historical':
        categoryDescription =
            'Historical tours showcase the rich heritage of Buganda kingdom, including royal tombs, ancient sites, and significant landmarks that tell the story of Uganda\'s past.';
        break;
      case 'cultural':
        categoryDescription =
            'Cultural tours immerse you in the vibrant traditions of Buganda, from traditional music and dance to local markets and community life.';
        break;
      case 'royal':
        categoryDescription =
            'Royal tours explore the majesty of the Buganda monarchy, visiting palaces, royal sites, and learning about the kingdom\'s governance and traditions.';
        break;
      case 'spiritual':
        categoryDescription =
            'Spiritual tours visit sacred sites, religious landmarks, and places of pilgrimage that hold deep spiritual significance for the people of Buganda.';
        break;
      case 'nature':
        categoryDescription =
            'Nature tours connect you with Uganda\'s beautiful landscapes, from the shores of Lake Victoria to natural reserves and scenic viewpoints.';
        break;
      case 'adventure':
        categoryDescription =
            'Adventure tours offer exciting experiences, from exploring markets to boat tours and outdoor activities that showcase the region\'s natural beauty.';
        break;
      case 'educational':
        categoryDescription =
            'Educational tours provide deep insights into Buganda\'s history, culture, and traditions through guided experiences and interactive learning.';
        break;
      default:
        categoryDescription = 'All tours are available for exploration.';
    }

    _ttsService.speakWithPriority(
      'Filtering by $category tours. $categoryDescription',
    );
  }

  void _onTourSelected(TourModel tour) {
    if (!mounted) return;
    final tourIndex = _filteredTours.indexOf(tour);
    setState(() {
      _currentTourIndex = tourIndex;
    });

    // Enhanced tour description with accessibility information
    String tourDescription =
        '''
Selected ${tour.title}. 
${tour.description}
Duration: ${tour.duration}. Distance: ${tour.distance}.
Accessibility: ${tour.accessibility}.
Highlights: ${tour.highlights}.
''';

    if (tour.audioDescription != null && tour.audioDescription!.isNotEmpty) {
      tourDescription += '\nDetailed description: ${tour.audioDescription}';
    }

    _ttsService.speakWithPriority(tourDescription);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Buganda'),
        actions: const [VoiceStatusWidget()],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildCategoriesSection(),
          Expanded(child: _buildToursSection()),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 2),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SearchBarWidget(
        onSearchChanged: _onSearchChanged,
        hintText: 'Search Buganda tours...',
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _onCategorySelected(category),
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToursSection() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Buganda tours...'),
          ],
        ),
      );
    }

    if (_filteredTours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No tours found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                });
                _filterTours();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTours,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTours.length,
        itemBuilder: (context, index) {
          final tour = _filteredTours[index];
          final isCurrentTour = index == _currentTourIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TourCardWidget(
              tour: tour,
              onTap: () => _onTourSelected(tour),
              isHighlighted: isCurrentTour,
            ),
          );
        },
      ),
    );
  }
}
