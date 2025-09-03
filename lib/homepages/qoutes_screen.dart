import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qoute_gallery_app/constants/colors.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class QoutesScreen extends StatefulWidget {
  const QoutesScreen({super.key});

  @override
  State<QoutesScreen> createState() => _QoutesScreenState();
}

class _QoutesScreenState extends State<QoutesScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final List<Map<String, String>> _quotes = [];

  bool _isLoading = false;

  Future<void> fetchQuote() async {
    try {
      setState(() => _isLoading = true);
      final response = await http.get(Uri.parse("https://favqs.com/api/qotd"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic>? quoteObj = data['quote'] as Map<String, dynamic>?;
        final String body = (quoteObj?['body'] ?? '').toString();
        final String author = (quoteObj?['author'] ?? 'Unknown').toString();
        if (body.isNotEmpty) {
          setState(() {
            _quotes.insert(0, {
              'text': '“$body”',
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _currentIndex = 0;
  final Set<int> _favorites = <int>{};

  void _copyQuote() async {
    if (_quotes.isEmpty) return;
    final quote = _quotes[_currentIndex];
    await Clipboard.setData(ClipboardData(text: '${quote['text']} ${quote['author']}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied')),
    );
  }

  void _shareQuote() {
    if (_quotes.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share coming soon')),
    );
  }

  void _toggleFavorite() {
    if (_quotes.isEmpty) return;
    setState(() {
      if (_favorites.contains(_currentIndex)) {
        _favorites.remove(_currentIndex);
      } else {
        _favorites.add(_currentIndex);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchQuote();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _quotes.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text("Qoutes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Hey! Are you doing good?\n Here are some qoutes to help your day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(
                height: 1.4,
                fontSize: 16,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          _isLoading ? 'Fetching quotes…' : 'No quotes yet',
                          style: GoogleFonts.figtree(
                            color: AppColors.textColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isLoading)
                          ElevatedButton.icon(
                            onPressed: fetchQuote,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                      ],
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _quotes.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final quote = _quotes[index];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double scale = 1.0;
                          if (_pageController.position.haveDimensions) {
                            final page = _pageController.page ?? _currentIndex.toDouble();
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
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
                                    const SizedBox(height: 12),
                                    Text(
                                      quote['author'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textColor.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.copy, color: AppColors.textColor),
                                          tooltip: 'Copy',
                                          onPressed: _copyQuote,
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.share_outlined, color: AppColors.textColor),
                                          tooltip: 'Share',
                                          onPressed: _shareQuote,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _favorites.contains(index)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: _favorites.contains(index)
                                                ? Colors.redAccent
                                                : AppColors.textColor,
                                          ),
                                          tooltip: 'Favorite',
                                          onPressed: _toggleFavorite,
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
          const SizedBox(height: 16),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchQuote,
        icon: const Icon(Icons.shuffle, color: AppColors.textColor,),
        label: const Text('New Quote', style: TextStyle(color: AppColors.textColor),),
        backgroundColor: AppColors.drawerBackgroundColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}