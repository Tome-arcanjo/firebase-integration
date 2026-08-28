import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tarefas.dart';
import 'app_theme.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key});

  @override
  State<TarefasPage> createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> {
  final _tituloController = TextEditingController();
  bool _salvando = false;

  Future<void> _salvar() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) return;

    setState(() => _salvando = true);
    try {
      await adicionarTarefa(titulo);
      _tituloController.clear();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _confirmarDelecao(BuildContext context, String id, String titulo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover tarefa'),
        content: Text('Deseja remover "$titulo"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar == true) await deletarTarefa(id);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarefas', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Formulário ──────────────────────────────────────────────────
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tituloController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _salvar(),
                    style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: 'Nome da tarefa...',
                      hintStyle: GoogleFonts.inter(color: Colors.black38),
                      filled: true,
                      fillColor: AppTheme.backgroundLightGrey,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryDarkBlue, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(_salvando ? '' : 'Salvar',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divisor ─────────────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),

          // ── Lista em tempo real ──────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: lerTarefasEmTempoReal(),
              builder: (context, snapshot) {
                // Estado de carregamento
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Erro
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Lista vazia
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checklist_rounded, size: 64, color: Colors.black12),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma tarefa ainda.',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.black38),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adicione uma tarefa acima!',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.black26),
                        ),
                      ],
                    ),
                  );
                }

                // Lista preenchida
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final titulo = data['titulo'] as String? ?? '';
                    final concluida = data['concluida'] as bool? ?? false;

                    return _TarefaCard(
                      id: doc.id,
                      titulo: titulo,
                      concluida: concluida,
                      onToggle: (val) => atualizarTarefa(doc.id, val),
                      onDelete: () => _confirmarDelecao(context, doc.id, titulo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget do card de tarefa ────────────────────────────────────────────────
class _TarefaCard extends StatelessWidget {
  final String id;
  final String titulo;
  final bool concluida;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _TarefaCard({
    required this.id,
    required this.titulo,
    required this.concluida,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: concluida,
          activeColor: AppTheme.primaryDarkBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (val) => onToggle(val ?? false),
        ),
        title: Text(
          titulo,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: concluida ? Colors.black38 : AppTheme.textDark,
            decoration: concluida ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          tooltip: 'Remover',
          onPressed: onDelete,
        ),
      ),
    );
  }
}
