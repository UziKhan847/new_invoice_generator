import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_invoice_generator/app_theme.dart';

/// Standard desktop page top bar: title + subtitle on the left, actions on the
/// right. Used by every desktop screen for a consistent header.
class DesktopTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  const DesktopTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTypography.display(p.ink).copyWith(fontSize: 24),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.bodyMuted(p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 14),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact desktop search field for the top bar. Supports an external
/// [focusNode] (so a shortcut like Ctrl+F can jump into it) and a clear
/// button once there's text to clear.
class DesktopSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final double width;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  const DesktopSearchField({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.width = 260,
    this.controller,
    this.focusNode,
  });

  @override
  State<DesktopSearchField> createState() => _DesktopSearchFieldState();
}

class _DesktopSearchFieldState extends State<DesktopSearchField> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return SizedBox(
      width: widget.width,
      height: 42,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.escape): _ClearSearchIntent(),
          },
          child: Actions(
            actions: {
              _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(
                onInvoke: (_) {
                  _clear();
                  return null;
                },
              ),
            },
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: AppTypography.body(p.ink).copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: Icon(Icons.search, size: 18, color: p.textTertiary),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: 'Clear (Esc)',
                        onPressed: _clear,
                      ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearSearchIntent extends Intent {
  const _ClearSearchIntent();
}

/// Right-click context menu for a row. Left-click / hover behavior is left
/// to the child (usually a `Material` + `InkWell`) — this only adds the
/// secondary-click affordance desktop users expect.
class ContextMenuRegion<T> extends StatelessWidget {
  final Widget child;
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T> onSelected;
  const ContextMenuRegion({
    super.key,
    required this.child,
    required this.itemBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) async {
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final selected = await showMenu<T>(
          context: context,
          position: RelativeRect.fromRect(
            details.globalPosition & const Size(1, 1),
            Offset.zero & overlay.size,
          ),
          items: itemBuilder(context),
        );
        if (selected != null) onSelected(selected);
      },
      child: child,
    );
  }
}

/// Wraps a row with a hover-tinted background and a click cursor — the
/// default `InkWell` hover overlay is too subtle to read as "this row is
/// interactive" in a dense table on desktop.
class HoverableRow extends StatefulWidget {
  final Widget child;
  final Color? hoverColor;
  const HoverableRow({super.key, required this.child, this.hoverColor});

  @override
  State<HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<HoverableRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovering
            ? (widget.hoverColor ?? p.surfaceAlt)
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

/// A KPI card for the desktop dashboards: icon tile top-left, optional badge
/// top-right, big value, label underneath.
class DesktopKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color fg;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeFg;
  const DesktopKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.fg,
    this.badge,
    this.badgeBg,
    this.badgeFg,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                ),
                child: Icon(icon, color: fg, size: 19),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg ?? p.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.caption(
                      badgeFg ?? p.textSecondary,
                    ).copyWith(fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amount(p.ink).copyWith(fontSize: 26),
          ),
          const SizedBox(height: 3),
          Text(label, style: AppTypography.bodyMuted(p.textSecondary)),
        ],
      ),
    );
  }
}

/// A surface card wrapper for desktop content blocks (white, bordered, shadowed).
class DesktopPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const DesktopPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: child,
    );
  }
}

/// A "+ New Invoice"-style primary button used in desktop top bars.
class DesktopPrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const DesktopPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
    );
  }
}

/// Wraps an existing mobile screen so it renders cleanly inside a desktop
/// content pane. A nested [Navigator] gives it a fresh routing root, so its
/// own AppBar shows no spurious back arrow (it can't pop past this
/// boundary), and any dialogs/sheets it opens still work.
class EmbeddedMobileSection extends StatelessWidget {
  final Widget child;
  const EmbeddedMobileSection({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        color: p.surface,
        child: Navigator(
          onGenerateRoute: (settings) =>
              MaterialPageRoute(settings: settings, builder: (_) => child),
        ),
      ),
    );
  }
}
