import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(CDManagerApp());

class CDManagerApp extends StatelessWidget {
  const CDManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestionnaire de CD',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CDListScreen(),
    );
  }
}

class CD {
  String title;
  String artist;
  File? image;

  CD({required this.title, required this.artist, this.image});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'image': image?.path,
    };
  }

  static CD fromJson(Map<String, dynamic> json) {
    return CD(
      title: json['title'],
      artist: json['artist'],
      image: json['image'] != null ? File(json['image']) : null,
    );
  }
}

class CDListScreen extends StatefulWidget {
  const CDListScreen({super.key});

  @override
  _CDListScreenState createState() => _CDListScreenState();
}

class _CDListScreenState extends State<CDListScreen> {
  List<CD> cds = [];
  List<CD> filteredCDs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCDs();
    _searchController.addListener(_filterCDs);
  }

  Future<void> _saveCDs() async {
    final prefs = await SharedPreferences.getInstance();
    final cdListJson = cds.map((cd) => cd.toJson()).toList();
    prefs.setString('cdList', jsonEncode(cdListJson));
  }

  Future<void> _loadCDs() async {
    final prefs = await SharedPreferences.getInstance();
    final cdListString = prefs.getString('cdList');
    if (cdListString != null) {
      final cdListJson = jsonDecode(cdListString) as List;
      setState(() {
        cds = cdListJson.map((json) => CD.fromJson(json)).toList();
        filteredCDs = cds;
      });
    }
  }

  void _filterCDs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredCDs = cds.where((cd) {
        return cd.artist.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addCD(CD cd) {
    setState(() {
      cds.add(cd);
      filteredCDs = cds;
    });
    _saveCDs();
  }

  void _removeCD(int index) {
    setState(() {
      cds.removeAt(index);
      filteredCDs = cds;
    });
    _saveCDs();
  }

  void _navigateToAddCDScreen() async {
    final CD? newCD = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCDScreen()),
    );
    if (newCD != null) {
      _addCD(newCD);
    }
  }

  void _showImagePreview(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ma collection de CD'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un artiste',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCDs.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: filteredCDs[index].image != null
                      ? () => _showImagePreview(filteredCDs[index].image!)
                      : null,
                  child: Card(
                    child: ListTile(
                      leading: filteredCDs[index].image != null
                          ? Image.file(filteredCDs[index].image!,
                              width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.album, size: 50),
                      title: Text(filteredCDs[index].title),
                      subtitle: Text(filteredCDs[index].artist),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeCD(index),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCDScreen,
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddCDScreen extends StatefulWidget {
  const AddCDScreen({super.key});

  @override
  _AddCDScreenState createState() => _AddCDScreenState();
}

class _AddCDScreenState extends State<AddCDScreen> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  File? _image;

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _submitCD() {
    final title = _titleController.text;
    final artist = _artistController.text;

    if (title.isEmpty || artist.isEmpty) return;

    final newCD = CD(title: title, artist: artist, image: _image);
    Navigator.pop(context, newCD);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un nouveau CD'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Titre'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: InputDecoration(labelText: 'Artiste'),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: Text('Choisir une image'),
                ),
                ElevatedButton(
                  onPressed: _pickImageFromCamera,
                  child: Text('Prendre une photo'),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitCD,
              child: Text('Ajouter le CD'),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final File image;

  const ImagePreviewScreen({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aperçu de l\'image'),
      ),
      body: Center(
        child: Image.file(image, fit: BoxFit.contain),
      ),
    );
  }
}
