import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qoute_gallery_app/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class MyGalleryScreen extends StatefulWidget {
  const MyGalleryScreen({super.key});

  @override
  State<MyGalleryScreen> createState() => _MyGalleryScreenState();
}

class _MyGalleryScreenState extends State<MyGalleryScreen> 
//It's a mixin that you use with a StatefulWidget when you need animations.•	A Ticker is like a clock that "ticks" for every frame (usually 60 times per second).
 with SingleTickerProviderStateMixin
{
  // AnimationController manages the lifecycle and state of animations,
  // allowing control over play, pause, reverse, and duration of animated widgets
  late AnimationController _controller;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // PageController manages swipeable page transitions with viewportFraction: 0.9,
  // showing 90% of current page and 10% of adjacent pages for visual preview
  final PageController _imagePageController = PageController(viewportFraction: 0.9);

   final List<String> _images = [];

   int _currentImageIndex = 0;

   bool _isImageLoading = false;

   final Set<int> _favoriteImages = <int>{};

  /// Initialize the screen by setting up animation controller and fetching initial image
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _fetchImage();
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

  /// Download the current image to device gallery (placeholder for future implementation)
  void _downloadImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download feature coming soon')),
    );
  }

  /// Share the current image (placeholder for future implementation)
  void _shareImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  /// Build shimmer effect for header text
  Widget _buildShimmerHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 40,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Build shimmer effect for image card
  Widget _buildShimmerImageCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool imagesEmpty = _images.isEmpty;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Image Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.drawerBackgroundColor,
        foregroundColor: AppColors.textColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _fetchImage,
            icon: const Icon(Icons.refresh),
            tooltip: 'New Image',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _isImageLoading && imagesEmpty
                ? _buildShimmerHeader()
                : Text(
                    'Discover beautiful, randomly generated images\nSwipe to explore more!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      height: 1.4,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryColor,
                    ),
                  ),
          ),
          if (_isImageLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2, color: AppColors.backgroundColor,),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: imagesEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isImageLoading) ...[
                          _buildShimmerImageCard(),
                          const SizedBox(height: 16),
                          _buildShimmerHeader(),
                        ] else ...[
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Card(
                            color: AppColors.drawerBackgroundColor,
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                // Top-right favorite button
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _favoriteImages.contains(index) ? Icons.favorite : Icons.favorite_border,
                                        color: _favoriteImages.contains(index) ? Colors.redAccent : Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: _toggleFavoriteImage,
                                    ),
                                  ),
                                ),
                                // Bottom action buttons
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.download, color: Colors.white),
                                          tooltip: 'Download',
                                          onPressed: _downloadImage,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Colors.white),
                                          tooltip: 'Share',
                                          onPressed: _shareImage,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline, color: Colors.white),
                                          tooltip: 'Info',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Image Info'),
                                                content: Text('Image ${index + 1} of ${_images.length}'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
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
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchImage,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('New Image', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.drawerBackgroundColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}