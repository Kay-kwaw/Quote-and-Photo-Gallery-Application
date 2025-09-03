import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qoute_gallery_app/constants/colors.dart';
import 'package:qoute_gallery_app/constants/images.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

import 'package:qoute_gallery_app/homepages/qoutes_screen.dart';
import 'package:qoute_gallery_app/homepages/gallery_screen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final PageController _imagePageController = PageController(viewportFraction: 0.9);
  final PageController _quotePageController = PageController(viewportFraction: 0.9);

  final List<String> _images = [];
  final List<Map<String, String>> _quotes = [];

  int _currentImageIndex = 0;
  int _currentQuoteIndex = 0;

  bool _isImageLoading = false;
  bool _isQuoteLoading = false;

  final Set<int> _favoriteImages = <int>{};
  final Set<int> _favoriteQuotes = <int>{};

  /// Build shimmer effect for image card
  Widget _buildShimmerImageCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Build shimmer effect for quote card
  Widget _buildShimmerQuoteCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Initialize the screen by setting up animation controller and fetching initial data
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _fetchImage();
    _fetchQuote();
  }

  /// Clean up resources when the widget is disposed
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fetch a random image from Picsum API and add it to the images list
  /// Uses timestamp + random seed to ensure unique images on each fetch
  Future<void> _fetchImage() async {
    try {
      setState(() => _isImageLoading = true);
      final int seed = DateTime.now().millisecondsSinceEpoch + Random().nextInt(100000);
      final String url = 'https://picsum.photos/seed/$seed/800/1200';
      await http.get(Uri.parse(url));
      if (!mounted) return;
      setState(() {
        _images.insert(0, url);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load image')),
      );
    } finally {
      if (mounted) setState(() => _isImageLoading = false);
    }
  }

  /// Fetch a daily quote from FavQs API and add it to the quotes list
  /// Parses the JSON response to extract quote text and author
  Future<void> _fetchQuote() async {
    try {
      setState(() => _isQuoteLoading = true);
      final response = await http.get(Uri.parse("https://favqs.com/api/qotd"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic>? quoteObj = data['quote'] as Map<String, dynamic>?;
        final String body = (quoteObj?['body'] ?? '').toString();
        final String author = (quoteObj?['author'] ?? 'Unknown').toString();
        if (body.isNotEmpty) {
          setState(() {
            _quotes.insert(0, {
              'text': '"$body"',
              'author': '— $author',
            });
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch quote')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred fetching quote')),
      );
    } finally {
      if (mounted) setState(() => _isQuoteLoading = false);
    }
  }

  /// Toggle favorite status for the currently displayed image
  /// Adds or removes the image index from the favorites set
  void _toggleFavoriteImage() {
    setState(() {
      if (_favoriteImages.contains(_currentImageIndex)) {
        _favoriteImages.remove(_currentImageIndex);
      } else {
        _favoriteImages.add(_currentImageIndex);
      }
    });
  }

  /// Toggle favorite status for the currently displayed quote
  /// Adds or removes the quote index from the favorites set
  void _toggleFavoriteQuote() {
    if (_quotes.isEmpty) return;
    setState(() {
      if (_favoriteQuotes.contains(_currentQuoteIndex)) {
        _favoriteQuotes.remove(_currentQuoteIndex);
      } else {
        _favoriteQuotes.add(_currentQuoteIndex);
      }
    });
  }

  /// Copy the current quote text and author to the device clipboard
  /// Shows a snackbar confirmation when the quote is copied
  Future<void> _copyCurrentQuote() async {
    if (_quotes.isEmpty) return;
    final quote = _quotes[_currentQuoteIndex];
    await Clipboard.setData(ClipboardData(text: '${quote['text']} ${quote['author']}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied')),
    );
  }

  /// Build the main UI with app bar, drawer, and content sections
  /// Displays images and quotes in swipeable PageViews with loading states
  @override
  Widget build(BuildContext context) {
    final bool imagesEmpty = _images.isEmpty;
    final bool quotesEmpty = _quotes.isEmpty;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Qoute & Photo Gallery App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold ),),
        centerTitle: true,
        leading: IconButton(onPressed: () {
         _scaffoldKey.currentState?.openDrawer();
        }, icon: Icon(Icons.menu)),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
        ],
      ),
      drawer: Drawer(
        elevation: 10,
        backgroundColor: AppColors.drawerBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            children: [
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: Image.asset(AppImages.logo, width: 100, height: 100,),
             ),
             const SizedBox(height: 24),
             ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
               leading: Icon(Icons.home, color: AppColors.textColor),
               title: Text('Home', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
               onTap: () {},
             ),
             ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
               leading: Icon(Icons.format_quote_sharp, color: AppColors.textColor),
               title: Text('Qoutes', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
               onTap: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QoutesScreen()),
                );
               },
             ),
             ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
               leading: Icon(Icons.photo_album, color: AppColors.textColor),
               title: Text('Photos', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
               onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyGalleryScreen()),
                );
               },
             ),
             ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
               leading: Icon(Icons.video_library, color: AppColors.textColor),
               title: Text('Videos', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
               onTap: () {},
             ),
             ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
               leading: Icon(Icons.saved_search_outlined, color: AppColors.textColor),
               title: Text('Saved Files', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
               onTap: () {},
             ),
             ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
               leading: Icon(Icons.rate_review, color: AppColors.textColor),
               title: Text('Rate Us', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
               onTap: () {},
             ),
             ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
               leading: Icon(Icons.contact_mail, color: AppColors.textColor),
               title: Text('Share', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
               onTap: () {},
             ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Welcome back!\nExplore auto-generated images and quotes for inspiration.',
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(
                height: 1.4,
                fontSize: 16,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
          if (_isImageLoading || _isQuoteLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 12),
          // Images section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Images', style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'New Image',
                  onPressed: _fetchImage,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: imagesEmpty
                ? Center(
                    child: _isImageLoading
                        ? _buildShimmerImageCard()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No images yet',
                                style: GoogleFonts.figtree(
                                  color: AppColors.textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _fetchImage,
                                icon: const Icon(Icons.image),
                                label: const Text('Load image'),
                              ),
                            ],
                          ),
                  )
                : PageView.builder(
                    controller: _imagePageController,
                    itemCount: _images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      final String imageUrl = _images[index];
                      return AnimatedBuilder(
                        animation: _imagePageController,
                        builder: (context, child) {
                          double scale = 1.0;
                          if (_imagePageController.position.haveDimensions) {
                            final page = _imagePageController.page ?? _currentImageIndex.toDouble();
                            scale = (1 - (page - index).abs() * 0.08).clamp(0.9, 1.0);
                          }
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Card(
                            color: AppColors.drawerBackgroundColor,
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return _buildShimmerImageCard();
                                    },
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Icon(Icons.broken_image, color: AppColors.textColor.withOpacity(0.6)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      _favoriteImages.contains(index) ? Icons.favorite : Icons.favorite,
                                      color: _favoriteImages.contains(index) ? Colors.redAccent : Colors.white,
                                    ),
                                    onPressed: _toggleFavoriteImage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          // Quotes section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Quotes', style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'New Quote',
                  onPressed: _fetchQuote,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: quotesEmpty
                ? Center(
                    child: _isQuoteLoading
                        ? _buildShimmerQuoteCard()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No quotes yet',
                                style: GoogleFonts.figtree(
                                  color: AppColors.textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _fetchQuote,
                                icon: const Icon(Icons.format_quote),
                                label: const Text('Load quote'),
                              ),
                            ],
                          ),
                  )
                : PageView.builder(
                    controller: _quotePageController,
                    itemCount: _quotes.length,
                    onPageChanged: (i) => setState(() => _currentQuoteIndex = i),
                    itemBuilder: (context, index) {
                      final quote = _quotes[index];
                      return AnimatedBuilder(
                        animation: _quotePageController,
                        builder: (context, child) {
                          double scale = 1.0;
                          if (_quotePageController.position.haveDimensions) {
                            final page = _quotePageController.page ?? _currentQuoteIndex.toDouble();
                            scale = (1 - (page - index).abs() * 0.08).clamp(0.9, 1.0);
                          }
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Card(
                              color: AppColors.drawerBackgroundColor,
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quote['text'] ?? '',
                                      style: GoogleFonts.figtree(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: AppColors.textColor,
                                        fontWeight: FontWeight.w600
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      quote['author'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textColor.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.copy, color: AppColors.textColor),
                                          tooltip: 'Copy',
                                          onPressed: _copyCurrentQuote,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _favoriteQuotes.contains(index) ? Icons.favorite : Icons.favorite_border,
                                            color: _favoriteQuotes.contains(index) ? Colors.redAccent : AppColors.textColor,
                                          ),
                                          tooltip: 'Favorite',
                                          onPressed: _toggleFavoriteQuote,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: [
          FloatingActionButton.extended(
            heroTag: 'imgFab',
            backgroundColor: AppColors.textColor,
            onPressed: _fetchImage,
            icon: const Icon(Icons.image, color:AppColors.drawerBackgroundColor),
            label: const Text('New Image', style: TextStyle(color: AppColors.drawerBackgroundColor),),
          ),
          FloatingActionButton.extended(
            heroTag: 'quoteFab',
            onPressed: _fetchQuote,
            backgroundColor: AppColors.drawerBackgroundColor,
            icon: const Icon(Icons.format_quote, color: Colors.white),
            label: const Text('New Quote', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}