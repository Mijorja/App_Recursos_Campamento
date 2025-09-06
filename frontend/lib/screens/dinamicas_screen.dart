import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class DinamicasScreen extends StatefulWidget {
  const DinamicasScreen({super.key});

  @override
  State<DinamicasScreen> createState() => _DinamicasScreenState();
}

class _DinamicasScreenState extends State<DinamicasScreen> {
  int? selectedAnio;
  String? selectedGrupo;
  String searchQuery = "";
  List<Recurso> recursos = [];
  List<int> availableYears = [];
  bool loading = true;

  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  final grupos = ["Pequeños", "Medianos", "Mayores"];

  @override
  void initState() {
    super.initState();
    fetchYearsAndRecursos();

    // Listener para detectar cuando llegamos al final
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !loading &&
          hasMore) {
        fetchMoreRecursos();
      }
    });
  }

  Future<void> fetchYearsAndRecursos() async {
    setState(() {
      loading = true;
      currentPage = 1;
      hasMore = true;
    });

    try {
      final years = await ApiService.getYearsDinamicas();
      final data = await ApiService.getRecursos(
        tipo: "dinamica",
        anio: selectedAnio,
        grupo: selectedGrupo,
        q: searchQuery.isNotEmpty ? searchQuery : null,
        page: currentPage,
        limit: 50,
      );

      setState(() {
        availableYears = years;
        if (selectedAnio == null && years.isNotEmpty) {
          selectedAnio = years.first; // inicializa con el más reciente
        }
        recursos = data;
        loading = false;
        hasMore = data.length == 50;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> fetchMoreRecursos() async {
    if (!hasMore) return;

    setState(() => loading = true);
    
    try {
      final data = await ApiService.getRecursos(
        tipo: "dinamica",
        anio: selectedAnio,
        grupo: selectedGrupo,
        q: searchQuery.isNotEmpty ? searchQuery : null,
        page: currentPage,
        limit: 50,
      );
      setState(() {
        recursos.addAll(data);
        loading = false;
        hasMore = data.length == 50;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dinámicas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            mainNavKey.currentState?.setIndex(0);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar dinámicas...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                setState(() => searchQuery = value);
                fetchMoreRecursos();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                DropdownButton<int>(
                  hint: const Text("Año"),
                  value: selectedAnio,
                  items: availableYears
                      .map((a) => DropdownMenuItem(value: a, child: Text("$a")))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedAnio = v);
                    fetchMoreRecursos();
                  },
                ),
                DropdownButton<String>(
                  hint: const Text("Grupo"),
                  value: selectedGrupo,
                  items: grupos
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedGrupo = v);
                    fetchMoreRecursos();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ResourceScreen(recursos: recursos),
          ),
        ],
      ),
    );
  }
}
