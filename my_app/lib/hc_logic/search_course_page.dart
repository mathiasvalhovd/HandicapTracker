import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchCoursePage extends StatefulWidget {
  final String golfApiToken;
  const SearchCoursePage({required this.golfApiToken, super.key});

  @override
  State<SearchCoursePage> createState() => _SearchCoursePageState();
}

class _SearchCoursePageState extends State<SearchCoursePage> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  final TextEditingController _controller = TextEditingController();

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _results = [];
    });
    try {
      final response = await http.get(
        Uri.parse('https://api.golfcourseapi.com/v1/search?search_query=${Uri.encodeComponent(query)}'),
        headers: {'Authorization': 'Key ${widget.golfApiToken}'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final courses = (decoded['courses'] as List)
            .map<Map<String, dynamic>>((c) => c as Map<String, dynamic>)
            .toList();
        setState(() {
          _results = courses;
        });
      } else {
        setState(() {
          _results = [];
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Golf Course')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Course Name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading)
              Expanded(
                child: _results.isEmpty
                    ? const Center(child: Text('No results'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, idx) {
                          final course = _results[idx];
                          final name = course['course_name'] ?? course['club_name'] ?? '';
                          final address = course['location']?['address'] ?? '';
                          return ListTile(
                            title: Text(name),
                            subtitle: Text(address),
                            onTap: () {
                              Navigator.pop(context, course);
                            },
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
