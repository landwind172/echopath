import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/voice_navigation_provider.dart';
import '../services/tts_service.dart';
import '../services/download_service.dart';
import '../services/dependency_injection.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/voice_status_widget.dart';
import '../widgets/audio_player_widget.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final TTSService _ttsService = getIt<TTSService>();
  final DownloadService _downloadService = getIt<DownloadService>();

  bool _isLoading = true;
  List<String> _downloadedTours = [];
  List<Map<String, dynamic>> _offlineContent = [];
  String _selectedCategory = 'All';
  int _currentContentIndex = 0;

  final List<String> _categories = [
    'All',
    'Tours',
    'Guides',
    'Stories',
    'Music',
    'Language',
  ];

  // Pre-downloaded offline content for Buganda, Uganda
  final List<Map<String, dynamic>> _bugandaOfflineContent = [
    {
      'id': 'kasubi_offline_guide',
      'title': 'Kasubi Tombs Complete Guide',
      'type': 'Guides',
      'description':
          'Complete offline guide to Kasubi Tombs with detailed audio descriptions, historical background, and cultural significance.',
      'duration': '45 minutes',
      'size': '25 MB',
      'audioFiles': [
        'kasubi_intro.mp3',
        'kasubi_history.mp3',
        'kasubi_architecture.mp3',
        'kasubi_culture.mp3',
      ],
      'highlights':
          'Royal burial site, traditional architecture, cultural ceremonies, UNESCO heritage',
      'accessibility': 'Audio descriptions, braille guide available',
      'content': '''
Kasubi Tombs - The Sacred Burial Grounds of Buganda Kings

Welcome to Kasubi Tombs, the most sacred site in the Buganda kingdom. This UNESCO World Heritage site serves as the burial ground for the Kabakas (kings) of Buganda and holds immense spiritual and cultural significance.

Historical Background:
The tombs were established in 1882 by Kabaka Mutesa I, who chose this hilltop location for its spiritual significance. The site has been the burial place for four Kabakas: Mutesa I, Mwanga II, Daudi Chwa II, and Sir Edward Mutesa II.

Architecture:
The main building, Muzibu Azaala Mpanga, is a masterpiece of traditional architecture. The circular structure features a thatched roof supported by wooden poles, symbolizing the unity and strength of the Buganda kingdom. The building materials and construction techniques have been passed down through generations.

Cultural Significance:
The tombs are not just a burial site but a living cultural institution. They serve as a place for royal ceremonies, cultural rituals, and spiritual practices. The site is maintained by the Namasole (queen mother) and her attendants, who perform daily rituals to honor the ancestors.

Spiritual Importance:
For the Baganda people, the tombs are a bridge between the living and the dead. The spirits of the departed Kabakas are believed to continue watching over their people and providing guidance to the current king and kingdom.

Visitor Experience:
As you explore the site, you'll notice the peaceful atmosphere and the careful preservation of traditional practices. The guides will share stories of each Kabaka's reign and their contributions to the kingdom's development.

Accessibility Features:
- Audio guides available in multiple languages
- Braille information panels
- Wheelchair accessible paths
- Trained guides for visitors with visual impairments
- Assistance animals welcome

The Kasubi Tombs represent the enduring spirit of the Buganda kingdom and its commitment to preserving cultural heritage for future generations.
''',
    },
    {
      'id': 'buganda_language_guide',
      'title': 'Learn Luganda - Buganda Language Guide',
      'type': 'Language',
      'description':
          'Interactive offline language guide to learn basic Luganda phrases, greetings, and cultural expressions.',
      'duration': '30 minutes',
      'size': '15 MB',
      'audioFiles': [
        'luganda_greetings.mp3',
        'luganda_basics.mp3',
        'luganda_culture.mp3',
        'luganda_practice.mp3',
      ],
      'highlights':
          'Basic phrases, greetings, cultural expressions, pronunciation guide',
      'accessibility': 'Audio pronunciation, interactive lessons',
      'content': '''
Learn Luganda - The Language of Buganda

Welcome to your Luganda language learning guide! Luganda is the primary language of the Buganda kingdom and is spoken by millions of people in Uganda.

Basic Greetings:
- "Oli otya?" - How are you? (informal)
- "Mwasuze mutya?" - How are you? (formal)
- "Bulungi" - I'm fine
- "Webale" - Thank you
- "Webale nyo" - Thank you very much
- "Kale" - Okay/Alright

Common Phrases:
- "Nze" - I am
- "Ggwe" - You are
- "Wano" - Here
- "Wali" - There
- "Nga" - If/When
- "Naye" - But

Cultural Expressions:
- "Mukama" - Lord/God
- "Kabaka" - King
- "Nnamasole" - Queen Mother
- "Omukisa" - Blessing
- "Ekisa" - Grace
- "Obulamu" - Life

Numbers 1-10:
1. Emu
2. Bbiri
3. Ssatu
4. Nnya
5. Ttaano
6. Mukaaga
7. Musanvu
8. Munaana
9. Mwenda
10. Kkumi

Days of the Week:
- Monday: Balaza
- Tuesday: Lwakubiri
- Wednesday: Lwakusatu
- Thursday: Lwakuna
- Friday: Lwakutaano
- Saturday: Lwamukaaga
- Sunday: Sabbiiti

Cultural Context:
Luganda is more than just a language; it's a window into Buganda culture. The language reflects the kingdom's values, traditions, and worldview. Learning Luganda helps you connect more deeply with the people and culture of Buganda.

Pronunciation Tips:
- Double letters (like 'bb', 'gg', 'kk') are pronounced with emphasis
- Vowels are pronounced clearly: a, e, i, o, u
- The 'ny' sound is like the 'ñ' in Spanish
- Practice with native speakers when possible

Practice Exercises:
1. Greet someone in Luganda
2. Count from 1 to 10
3. Say "thank you" in different ways
4. Learn the days of the week
5. Practice basic conversation

Remember: Language learning is a journey. Be patient with yourself and enjoy the process of discovering a new culture through its language!
''',
    },
    {
      'id': 'buganda_stories_collection',
      'title': 'Buganda Folktales & Stories',
      'type': 'Stories',
      'description':
          'Collection of traditional Buganda folktales, legends, and stories passed down through generations.',
      'duration': '60 minutes',
      'size': '35 MB',
      'audioFiles': [
        'story_kintu.mp3',
        'story_nambi.mp3',
        'story_creation.mp3',
        'story_animals.mp3',
      ],
      'highlights':
          'Traditional folktales, cultural legends, moral stories, historical narratives',
      'accessibility': 'Audio storytelling, descriptive narratives',
      'content': '''
Buganda Folktales & Stories Collection

Welcome to the rich world of Buganda storytelling! These stories have been passed down through generations, teaching moral lessons, preserving history, and entertaining listeners.

The Story of Kintu and Nambi:
Long ago, when the world was young, there lived a man named Kintu. He was the first man on earth and lived alone with his cow. One day, Ggulu (God) sent his daughter Nambi to earth to fetch water. Nambi met Kintu and fell in love with him.

When Nambi returned to heaven, she told her father about Kintu. Ggulu was impressed by Kintu's character and allowed Nambi to marry him. However, Ggulu warned them to return to earth immediately after the wedding and never come back to heaven.

Nambi's brother Walumbe (Death) was angry that he wasn't invited to the wedding. He followed Kintu and Nambi to earth, bringing death with him. This story explains why death exists in the world and teaches the importance of following instructions.

The Creation of Buganda:
According to Buganda legend, the first Kabaka (king) was Kintu, who was chosen by the people for his wisdom and leadership. Kintu established the kingdom's laws, traditions, and governance system.

The story tells how Kintu organized the clans, established the royal court, and created the system of chiefs and advisors. He taught the people farming, hunting, and other essential skills.

The Clever Hare:
This popular folktale tells the story of a clever hare who outwits larger animals through intelligence and quick thinking. The story teaches that wisdom and cleverness are more valuable than physical strength.

The story has many variations but always emphasizes the importance of using one's mind to solve problems and the value of cooperation and friendship.

The Talking Drum:
This story explains the origin of the traditional drum communication system in Buganda. The drums were used to send messages across long distances and announce important events.

The story tells how the first drum was created and how different drum patterns came to represent different messages and announcements.

Moral Lessons:
These stories teach important values:
- Respect for elders and authority
- The importance of wisdom over strength
- The value of community and cooperation
- The consequences of disobedience
- The power of love and sacrifice

Cultural Significance:
These stories are more than entertainment; they are:
- Educational tools for teaching moral values
- Historical records of the kingdom's origins
- Cultural preservation mechanisms
- Entertainment for all ages
- Bonding experiences for families and communities

Storytelling Tradition:
In traditional Buganda society, storytelling was an important evening activity. Families would gather around the fire, and elders would share these stories with children. The stories were interactive, with listeners participating through questions and responses.

Modern Relevance:
These stories continue to be relevant today, teaching timeless lessons about:
- Leadership and governance
- Family and community values
- Environmental stewardship
- Conflict resolution
- Personal development

The stories of Buganda are a treasure trove of wisdom, entertainment, and cultural heritage that continues to inspire and educate people of all ages.
''',
    },
    {
      'id': 'buganda_music_collection',
      'title': 'Traditional Buganda Music',
      'type': 'Music',
      'description':
          'Collection of traditional Buganda music, songs, and instrumental pieces showcasing the kingdom\'s rich musical heritage.',
      'duration': '90 minutes',
      'size': '50 MB',
      'audioFiles': [
        'music_royal_drums.mp3',
        'music_amadinda.mp3',
        'music_ensoga.mp3',
        'music_folk_songs.mp3',
      ],
      'highlights':
          'Royal drum music, traditional instruments, folk songs, cultural performances',
      'accessibility': 'Audio descriptions, cultural context',
      'content': '''
Traditional Buganda Music Collection

Welcome to the rich musical heritage of Buganda! This collection showcases the diverse musical traditions that have been preserved and celebrated for generations.

Royal Drum Music:
The royal drums (Engoma) are the most sacred musical instruments in Buganda. They are used for royal ceremonies, coronations, and important state events. The drum patterns are complex and carry specific meanings.

The main royal drums include:
- Mujaguzo - The king's drum
- Namunjoloba - The queen's drum
- Kawuluguma - The prince's drum
- Kiwawu - The princess's drum

Each drum has its own rhythm and is played at specific occasions. The drummers are highly trained and their skills are passed down through generations.

Amadinda (Xylophone) Music:
The Amadinda is a traditional xylophone made of wooden keys placed over resonators. It's played by two musicians sitting opposite each other, creating complex interlocking patterns.

The Amadinda music is characterized by:
- Polyrhythmic patterns
- Call and response structures
- Improvisational elements
- Cultural significance

Ensoga (Harp) Music:
The Ensoga is a traditional harp with 8 strings, played by skilled musicians. It's used for storytelling, love songs, and spiritual music. The harp music is often accompanied by singing.

Folk Songs and Chants:
Buganda folk songs cover various themes:
- Love and relationships
- Work and daily life
- Historical events
- Spiritual and religious themes
- Social commentary

Musical Instruments:
Traditional Buganda instruments include:
- Drums (Engoma) - Various types for different occasions
- Xylophone (Amadinda) - Melodic instrument
- Harp (Ensoga) - String instrument
- Flutes (Endere) - Wind instruments
- Rattles (Ensasi) - Percussion instruments
- Lyres (Adungu) - String instruments

Cultural Significance:
Music in Buganda serves multiple purposes:
- Religious and spiritual ceremonies
- Royal and state functions
- Social gatherings and celebrations
- Storytelling and education
- Entertainment and recreation

Performance Context:
Traditional music is performed in various settings:
- Royal courts and ceremonies
- Religious services and rituals
- Social gatherings and celebrations
- Educational and cultural events
- Community festivals and festivals

Modern Influence:
Buganda traditional music continues to influence:
- Contemporary Ugandan music
- African music genres
- World music fusion
- Cultural preservation efforts
- Educational programs

Learning and Appreciation:
To fully appreciate Buganda music:
- Listen to the rhythmic patterns
- Pay attention to the cultural context
- Understand the historical significance
- Appreciate the skill of the musicians
- Recognize the social functions

The music of Buganda is a living tradition that continues to evolve while preserving the cultural heritage of the kingdom. It serves as a bridge between the past and present, connecting people to their roots and cultural identity.
''',
    },
    {
      'id': 'kampala_city_guide',
      'title': 'Kampala City Offline Guide',
      'type': 'Guides',
      'description':
          'Comprehensive offline guide to Kampala city, including landmarks, markets, transportation, and cultural sites.',
      'duration': '75 minutes',
      'size': '40 MB',
      'audioFiles': [
        'kampala_overview.mp3',
        'kampala_landmarks.mp3',
        'kampala_markets.mp3',
        'kampala_transport.mp3',
      ],
      'highlights':
          'City landmarks, markets, transportation, cultural sites, practical information',
      'accessibility':
          'Audio descriptions, navigation tips, accessibility information',
      'content': '''
Kampala City Offline Guide

Welcome to Kampala, the vibrant capital city of Uganda and the heart of the Buganda kingdom! This comprehensive guide will help you explore the city's rich history, culture, and modern life.

City Overview:
Kampala is built on seven hills, each with its own historical and cultural significance. The city combines traditional African culture with modern urban development, creating a unique and dynamic atmosphere.

The Seven Hills of Kampala:
1. Old Kampala Hill - Site of the first colonial fort
2. Mengo Hill - Traditional seat of Buganda kingdom
3. Kibuli Hill - Islamic cultural center
4. Namirembe Hill - Anglican cathedral
5. Rubaga Hill - Catholic cathedral
6. Nsambya Hill - Modern residential area
7. Kololo Hill - Government and diplomatic area

Major Landmarks:
- Independence Grounds - National celebrations and events
- Uganda Museum - Cultural and historical exhibits
- National Theatre - Performing arts venue
- Parliament Building - Government headquarters
- Makerere University - Premier educational institution

Markets and Shopping:
- Owino Market - Largest market in East Africa
- Nakasero Market - Fresh produce and local goods
- Craft Markets - Traditional crafts and souvenirs
- Shopping Malls - Modern retail experiences

Transportation:
- Boda-boda (motorcycle taxis) - Fast and flexible
- Matatus (minibus taxis) - Affordable public transport
- Taxis - Private and shared options
- Walking - Best way to explore city center

Cultural Sites:
- Kasubi Tombs - UNESCO World Heritage site
- Lubiri Palace - Royal residence
- Bulange Parliament - Traditional governance
- Religious sites - Cathedrals, mosques, temples

Practical Information:
- Currency: Ugandan Shilling (UGX)
- Language: English, Luganda, Swahili
- Time Zone: East Africa Time (UTC+3)
- Weather: Tropical climate with two rainy seasons

Safety Tips:
- Use registered transportation
- Keep valuables secure
- Be aware of surroundings
- Respect local customs
- Follow local advice

Accessibility:
- Many sites have wheelchair access
- Audio guides available at major attractions
- Trained guides for visitors with disabilities
- Assistance animals welcome

Local Customs:
- Greet people respectfully
- Dress modestly at religious sites
- Ask permission before taking photos
- Respect traditional ceremonies
- Learn basic Luganda phrases

Food and Dining:
- Traditional Ugandan cuisine
- International restaurants
- Street food and local eateries
- Fresh produce markets
- Coffee shops and cafes

Entertainment:
- Live music venues
- Cultural performances
- Sports facilities
- Parks and recreation areas
- Nightlife and social venues

Kampala is a city of contrasts and opportunities, where tradition meets modernity, and visitors can experience the rich culture and warm hospitality of Uganda.
''',
    },
    {
      'id': 'buganda_culture_guide',
      'title': 'Buganda Culture & Traditions',
      'type': 'Guides',
      'description':
          'Comprehensive guide to Buganda culture, traditions, customs, and social practices.',
      'duration': '55 minutes',
      'size': '30 MB',
      'audioFiles': [
        'culture_overview.mp3',
        'culture_traditions.mp3',
        'culture_social.mp3',
        'culture_modern.mp3',
      ],
      'highlights':
          'Cultural practices, social customs, traditional ceremonies, modern adaptations',
      'accessibility': 'Audio descriptions, cultural explanations',
      'content': '''
Buganda Culture & Traditions Guide

Welcome to the rich cultural heritage of Buganda! This guide explores the traditions, customs, and social practices that have shaped the kingdom for centuries.

Cultural Overview:
Buganda culture is characterized by:
- Strong sense of community and family
- Respect for elders and authority
- Rich oral traditions and storytelling
- Vibrant music and dance traditions
- Sophisticated governance system
- Deep spiritual and religious beliefs

Social Structure:
The Buganda society is organized around:
- The Kabaka (King) - Spiritual and political leader
- The Namasole (Queen Mother) - Cultural guardian
- Chiefs and advisors - Administrative structure
- Clans - Extended family networks
- Villages and communities - Local organization

Traditional Ceremonies:
1. Coronation Ceremony - Installation of new Kabaka
2. Royal Weddings - Traditional marriage ceremonies
3. Naming Ceremonies - Welcoming new children
4. Funeral Rites - Honoring the departed
5. Harvest Celebrations - Thanksgiving ceremonies
6. Cultural Festivals - Annual celebrations

Family and Community:
- Extended family networks (clans)
- Respect for elders and ancestors
- Community cooperation and support
- Traditional education and apprenticeship
- Social responsibility and obligations

Religious Beliefs:
- Traditional spiritual practices
- Ancestor veneration
- Connection to nature and land
- Modern religious diversity
- Cultural tolerance and harmony

Arts and Crafts:
- Traditional pottery and ceramics
- Weaving and textile arts
- Wood carving and sculpture
- Metalwork and jewelry
- Musical instrument making

Dress and Adornment:
- Traditional bark cloth (Lubugo)
- Modern adaptations of traditional dress
- Cultural significance of clothing
- Ceremonial attire and accessories
- Contemporary fashion influences

Food and Cuisine:
- Traditional dishes and recipes
- Cultural significance of food
- Social aspects of dining
- Modern culinary influences
- Dietary customs and practices

Language and Communication:
- Luganda as cultural vehicle
- Oral traditions and storytelling
- Proverbs and wisdom sayings
- Modern communication methods
- Language preservation efforts

Education and Learning:
- Traditional apprenticeship systems
- Modern educational institutions
- Cultural knowledge transmission
- Skills development and training
- Lifelong learning traditions

Gender Roles and Relations:
- Traditional gender roles
- Modern adaptations and changes
- Women's leadership and influence
- Family dynamics and relationships
- Social equality and progress

Economic Activities:
- Traditional farming and agriculture
- Trade and commerce
- Modern business and entrepreneurship
- Cultural tourism and heritage
- Sustainable development

Environmental Stewardship:
- Traditional environmental knowledge
- Sustainable resource management
- Cultural connection to land
- Modern conservation efforts
- Climate change adaptation

Modern Adaptations:
- Preservation of traditional values
- Integration with modern life
- Cultural innovation and creativity
- Global cultural exchange
- Future cultural development

The culture of Buganda is a living, evolving tradition that continues to inspire and guide the people while adapting to modern challenges and opportunities.
''',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });

    // Listen for voice commands
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.addListener(_onVoiceCommandReceived);
    });
  }

  void _onVoiceCommandReceived() {
    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      if (voiceProvider.lastCommand.isNotEmpty) {
        _handleDownloadsVoiceCommands(voiceProvider.lastCommand);
        voiceProvider.clearLastCommand();
      }
    } catch (e) {
      // Ignore errors if context is no longer available
      debugPrint('Voice command error: $e');
    }
  }

  void _handleDownloadsVoiceCommands(String command) {
    final lowerCommand = command.toLowerCase();

    // Category filtering commands
    if (lowerCommand.contains('show tours') ||
        lowerCommand.contains('tour content')) {
      _onCategorySelected('Tours');
    } else if (lowerCommand.contains('show guides') ||
        lowerCommand.contains('guide content')) {
      _onCategorySelected('Guides');
    } else if (lowerCommand.contains('show stories') ||
        lowerCommand.contains('story content')) {
      _onCategorySelected('Stories');
    } else if (lowerCommand.contains('show music') ||
        lowerCommand.contains('music content')) {
      _onCategorySelected('Music');
    } else if (lowerCommand.contains('show language') ||
        lowerCommand.contains('language content')) {
      _onCategorySelected('Language');
    } else if (lowerCommand.contains('show all') ||
        lowerCommand.contains('all content')) {
      _onCategorySelected('All');
    }
    // Content-specific commands
    else if (lowerCommand.contains('kasubi guide') ||
        lowerCommand.contains('kasubi tombs guide')) {
      _playOfflineContent('kasubi_offline_guide');
    } else if (lowerCommand.contains('luganda') ||
        lowerCommand.contains('language guide')) {
      _playOfflineContent('buganda_language_guide');
    } else if (lowerCommand.contains('stories') ||
        lowerCommand.contains('folktales')) {
      _playOfflineContent('buganda_stories_collection');
    } else if (lowerCommand.contains('music') ||
        lowerCommand.contains('traditional music')) {
      _playOfflineContent('buganda_music_collection');
    } else if (lowerCommand.contains('kampala') ||
        lowerCommand.contains('city guide')) {
      _playOfflineContent('kampala_city_guide');
    } else if (lowerCommand.contains('culture') ||
        lowerCommand.contains('traditions')) {
      _playOfflineContent('buganda_culture_guide');
    }
    // Navigation commands
    else if (lowerCommand.contains('next content') ||
        lowerCommand.contains('next')) {
      _navigateToNextContent();
    } else if (lowerCommand.contains('previous content') ||
        lowerCommand.contains('previous')) {
      _navigateToPreviousContent();
    } else if (lowerCommand.contains('first content') ||
        lowerCommand.contains('start')) {
      _navigateToFirstContent();
    } else if (lowerCommand.contains('last content') ||
        lowerCommand.contains('end')) {
      _navigateToLastContent();
    }
    // Information commands
    else if (lowerCommand.contains('help') ||
        lowerCommand.contains('commands')) {
      _speakHelpCommands();
    } else if (lowerCommand.contains('content count') ||
        lowerCommand.contains('how many')) {
      _speakContentCount();
    } else if (lowerCommand.contains('current content') ||
        lowerCommand.contains('where am i')) {
      _speakCurrentContent();
    } else if (lowerCommand.contains('storage info') ||
        lowerCommand.contains('storage')) {
      _speakStorageInfo();
    }
  }

  void _playOfflineContent(String contentId) {
    final content = _bugandaOfflineContent.firstWhere(
      (c) => c['id'] == contentId,
      orElse: () => _bugandaOfflineContent.first,
    );

    _ttsService.speak('''
Playing ${content['title']}. 
${content['description']}
Duration: ${content['duration']}. Size: ${content['size']}.
Highlights: ${content['highlights']}.
Accessibility: ${content['accessibility']}.
''');

    // Simulate playing the content
    _ttsService.speak(
      'Starting offline content playback. Use voice commands to control playback.',
    );
  }

  void _navigateToNextContent() {
    if (!mounted) return;
    if (_offlineContent.isNotEmpty) {
      setState(() {
        _currentContentIndex =
            (_currentContentIndex + 1) % _offlineContent.length;
      });
      _speakCurrentContent();
    }
  }

  void _navigateToPreviousContent() {
    if (!mounted) return;
    if (_offlineContent.isNotEmpty) {
      setState(() {
        _currentContentIndex = _currentContentIndex > 0
            ? _currentContentIndex - 1
            : _offlineContent.length - 1;
      });
      _speakCurrentContent();
    }
  }

  void _navigateToFirstContent() {
    if (!mounted) return;
    if (_offlineContent.isNotEmpty) {
      setState(() {
        _currentContentIndex = 0;
      });
      _speakCurrentContent();
    }
  }

  void _navigateToLastContent() {
    if (!mounted) return;
    if (_offlineContent.isNotEmpty) {
      setState(() {
        _currentContentIndex = _offlineContent.length - 1;
      });
      _speakCurrentContent();
    }
  }

  void _speakCurrentContent() {
    if (_offlineContent.isNotEmpty) {
      final content = _offlineContent[_currentContentIndex];
      _ttsService.speak('''
Currently viewing content ${_currentContentIndex + 1} of ${_offlineContent.length}: ${content['title']}.
${content['description']}
''');
    }
  }

  void _speakContentCount() {
    _ttsService.speak(
      'There are ${_offlineContent.length} offline content items available in the current category.',
    );
  }

  void _speakHelpCommands() {
    _ttsService.speak('''
Available voice commands for downloads screen:
Categories: "Show tours", "Show guides", "Show stories", "Show music", "Show language"
Content: "Play Kasubi guide", "Play Luganda guide", "Play stories", "Play music", "Play Kampala guide"
Navigation: "Next content", "Previous content", "First content", "Last content"
Information: "Content count", "Current content", "Storage info", "Help commands"
''');
  }

  void _speakStorageInfo() {
    final totalSize = _calculateTotalSize();
    _ttsService.speak('''
Storage information: ${_downloadedTours.length} downloaded tours and ${_offlineContent.length} offline content items.
Total offline content size: $totalSize.
All content is available without internet connection.
''');
  }

  String _calculateTotalSize() {
    int totalMB = 0;
    for (final content in _bugandaOfflineContent) {
      final sizeStr = content['size'] as String;
      final mb = int.tryParse(sizeStr.replaceAll(' MB', '')) ?? 0;
      totalMB += mb;
    }
    return '$totalMB MB';
  }

  Future<void> _initializeScreen() async {
    await _ttsService.speak(
      'Offline content screen loaded. Welcome to your Buganda offline library! You have access to ${_bugandaOfflineContent.length} pre-downloaded guides, stories, music, and language lessons. Use voice commands like "show guides" or "play Kasubi guide" to explore. Say "help commands" for available options.',
    );

    await _loadDownloadedTours();
    _loadOfflineContent();

    // No automatic transition for main screens - user can navigate manually
  }

  void _loadOfflineContent() {
    if (!mounted) return;
    setState(() {
      _offlineContent = _bugandaOfflineContent;
    });
  }

  Future<void> _loadDownloadedTours() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await _downloadService.loadDownloadedTours();

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      setState(() {
        _downloadedTours = _downloadService.downloadedTours.toList();
        _isLoading = false;
      });

      if (_downloadedTours.isNotEmpty) {
        await _ttsService.speak(
          '${_downloadedTours.length} downloaded tours available for offline use.',
        );
      } else {
        await _ttsService.speak(
          'No downloaded tours found. Visit the discover screen to download tours for offline use.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      await _ttsService.speak('Error loading downloaded content.');
    }
  }

  void _onCategorySelected(String category) {
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _currentContentIndex = 0; // Reset to first content when category changes
    });

    // Filter content based on category
    if (category == 'All') {
      _offlineContent = _bugandaOfflineContent;
    } else {
      _offlineContent = _bugandaOfflineContent
          .where((content) => content['type'] == category)
          .toList();
    }

    // Enhanced speech narration for category selection
    String categoryDescription = '';
    switch (category.toLowerCase()) {
      case 'tours':
        categoryDescription =
            'Tour content includes guided tours of major Buganda sites with detailed audio descriptions and historical information.';
        break;
      case 'guides':
        categoryDescription =
            'Guide content provides comprehensive information about Buganda culture, history, and practical travel information.';
        break;
      case 'stories':
        categoryDescription =
            'Story content features traditional folktales, legends, and cultural narratives that have been passed down through generations.';
        break;
      case 'music':
        categoryDescription =
            'Music content showcases traditional Buganda music, songs, and instrumental pieces from the kingdom\'s rich musical heritage.';
        break;
      case 'language':
        categoryDescription =
            'Language content helps you learn Luganda, the language of Buganda, with pronunciation guides and cultural context.';
        break;
      default:
        categoryDescription =
            'All offline content is available for exploration.';
    }

    _ttsService.speak(
      'Filtering by $category content. $categoryDescription ${_offlineContent.length} items found.',
    );
  }

  Future<void> _playTour(String tourId) async {
    if (!mounted) return;

    // Get the AudioProvider before any async operations
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    try {
      final audioFiles = await _downloadService.getDownloadedAudioFiles(tourId);
      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      if (audioFiles.isNotEmpty) {
        audioProvider.setPlaylist(audioFiles);
        await audioProvider.playAtIndex(0);

        await _ttsService.speak(
          'Playing downloaded tour. Use voice commands to control playback.',
        );
      } else {
        await _ttsService.speak('No audio files found for this tour.');
      }
    } catch (e) {
      await _ttsService.speak('Error playing tour.');
    }
  }

  Future<void> _deleteTour(String tourId) async {
    if (!mounted) return;
    try {
      await _downloadService.deleteTour(tourId);
      await _loadDownloadedTours();
      await _ttsService.speak('Tour deleted successfully.');
    } catch (e) {
      await _ttsService.speak('Error deleting tour.');
    }
  }

  @override
  void dispose() {
    // Clean up voice navigation listener
    try {
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.removeListener(_onVoiceCommandReceived);
    } catch (e) {
      // Ignore errors during dispose
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Library'),
        actions: const [VoiceStatusWidget()],
      ),
      body: Column(
        children: [
          _buildStorageInfoSection(),
          _buildCategoriesSection(),
          Expanded(child: _buildContentSection()),
          Consumer<AudioProvider>(
            builder: (context, audioProvider, child) {
              if (audioProvider.currentAudioPath != null) {
                return const AudioPlayerWidget();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 3),
    );
  }

  Widget _buildStorageInfoSection() {
    final totalSize = _calculateTotalSize();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.storage, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Library',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_downloadedTours.length} tours + ${_offlineContent.length} guides',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Total: $totalSize',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _speakStorageInfo(),
            child: const Text('Info'),
          ),
        ],
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

  Widget _buildContentSection() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading offline content...'),
          ],
        ),
      );
    }

    if (_offlineContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.offline_pin,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Offline Content',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'All offline content is pre-loaded and available',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _offlineContent.length,
      itemBuilder: (context, index) {
        final content = _offlineContent[index];
        final isCurrentContent = index == _currentContentIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildOfflineContentCard(content, isCurrentContent),
        );
      },
    );
  }

  Widget _buildOfflineContentCard(
    Map<String, dynamic> content,
    bool isHighlighted,
  ) {
    return Card(
      elevation: isHighlighted ? 4 : 2,
      color: isHighlighted
          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
          : null,
      child: InkWell(
        onTap: () => _playOfflineContent(content['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getContentIcon(content['type']),
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content['title'],
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          content['type'],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      content['size'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content['description'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    content['duration'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      content['highlights'],
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (content['accessibility'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.accessibility, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        content['accessibility'],
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.green),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getContentIcon(String type) {
    switch (type) {
      case 'Tours':
        return Icons.tour;
      case 'Guides':
        return Icons.book;
      case 'Stories':
        return Icons.auto_stories;
      case 'Music':
        return Icons.music_note;
      case 'Language':
        return Icons.language;
      default:
        return Icons.folder;
    }
  }

  void _showDeleteConfirmation(String tourId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Tour'),
          content: const Text(
            'Are you sure you want to delete this downloaded tour?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _ttsService.speak('Delete cancelled');
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTour(tourId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    _ttsService.speak(
      'Delete confirmation dialog opened. Choose cancel or delete.',
    );
  }
}
