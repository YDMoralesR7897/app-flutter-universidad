import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/classroom.dart';
import '../bloc/campus_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<CampusBloc>().add(const CampusLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final email = auth.session?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Check-In U'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLoggedOut()),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.authBackground),
        child: BlocConsumer<CampusBloc, CampusState>(
          listener: (ctx, s) {
            final msg = s.error ?? s.info;
            if (msg != null) {
              ScaffoldMessenger.of(ctx)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(msg),
                  backgroundColor: s.error != null
                      ? const Color(0xFFB42318)
                      : AppColors.brand,
                ));
            }
          },
          builder: (ctx, s) {
            if (s.loading && s.classes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  ctx.read<CampusBloc>().add(const CampusLoaded()),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _AnimatedEntrance(
                    index: 0,
                    child: _HeroBanner(
                      email: email,
                      totalCheckIns: s.history.length,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AnimatedEntrance(
                    index: 1,
                    child: const _SectionTitle(
                      title: 'Clases disponibles',
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (s.classes.isEmpty)
                    const _AnimatedEntrance(
                      index: 2,
                      child: _EmptyCard(
                        message: 'No hay clases configuradas en este momento.',
                      ),
                    ),
                  ...List.generate(
                    s.classes.length,
                    (i) => _AnimatedEntrance(
                      index: i + 2,
                      child: _ClassCard(
                        classroom: s.classes[i],
                        loading: s.checkingInId == s.classes[i].id,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AnimatedEntrance(
                    index: s.classes.length + 3,
                    child: const _SectionTitle(
                      title: 'Historial reciente',
                      icon: Icons.history_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (s.history.isEmpty)
                    const _AnimatedEntrance(
                      index: 20,
                      child: _EmptyCard(
                        message: 'Aún no has registrado asistencia.',
                      ),
                    ),
                  ...List.generate(
                    s.history.length,
                    (i) => _AnimatedEntrance(
                      index: i + 4,
                      child: _HistoryCard(checkIn: s.history[i]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedEntrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedEntrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final durationMs = 320 + (index * 80);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: durationMs.clamp(320, 1200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 26),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String email;
  final int totalCheckIns;
  const _HeroBanner({required this.email, required this.totalCheckIns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.heroCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenido al campus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(
              color: Color(0xFFE5FFFB),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$totalCheckIns check-ins registrados',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brand),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: const Color(0xFF4B5563)),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Classroom classroom;
  final bool loading;
  const _ClassCard({required this.classroom, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${classroom.code} · ${classroom.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Radio permitido: ${classroom.radiusM} m',
              style: const TextStyle(color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading
                    ? null
                    : () => context
                        .read<CampusBloc>()
                        .add(CampusCheckInRequested(classroom)),
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.pin_drop_outlined),
                label: Text(loading ? 'Registrando...' : 'Hacer check-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CheckIn checkIn;
  const _HistoryCard({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final local = checkIn.createdAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: AppColors.brand),
        title: Text(checkIn.classroomName),
        subtitle: Text(
          '$day/$month/$year · $hour:$minute · ${checkIn.distanceM.toStringAsFixed(0)} m del aula',
        ),
      ),
    );
  }
}
