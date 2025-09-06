import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  int? selectedAnio;
  String? selectedMomento;
  String searchQuery = "";
  List<Recurso> recursos = [];
  List<int> availableYears = [];
  bool loading = true;

  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  final momentos = ["Mañana", "Tarde", "Velada", "Olimpiada"];

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
      final years = await ApiService.getYears();
      final data = await ApiService.getRecursos(
        tipo: "actividad",
        anio: selectedAnio,
        momento: selectedMomento,
        q: searchQuery.isNotEmpty ? searchQuery : null,
        page: currentPage,
        limit: 50,
      );

      setState(() {
        availableYears = years;
        selectedAnio = null;
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
      currentPage++;
      final data = await ApiService.getRecursos(
        tipo: "actividad",
        anio: selectedAnio,
        momento: selectedMomento,
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
        title: const Text("Actividades"),
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
                hintText: "Buscar actividades...",
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
                  hint: const Text("Tipo"),
                  value: selectedMomento,
                  items: momentos
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedMomento = v);
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
