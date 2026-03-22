import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/data/models/profile_models.dart';
import 'package:hero/data/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_history_cubit/cubit.dart';
import 'order_history_cubit/states.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderHistoryCubit()..loadOrders(),
      child: const _OrderHistoryBody(),
    );
  }
}

class _OrderHistoryBody extends StatefulWidget {
  const _OrderHistoryBody();
  @override
  State<_OrderHistoryBody> createState() => _OrderHistoryBodyState();
}

class _OrderHistoryBodyState extends State<_OrderHistoryBody> {
  RealtimeChannel? _channel;
  final _notificationService = NotificationService();
  final Map<int, String> _previousStatuses = {};

  @override
  void initState() {
    super.initState();
    _subscribeToOrderUpdates();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToOrderUpdates() {
    final supabase = Supabase.instance.client;
    final authUid = supabase.auth.currentUser?.id;
    if (authUid == null) return;
    _channel = supabase
        .channel('order_status_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final orderId = payload.newRecord['id'] as int?;
            final newStatus = payload.newRecord['status'] as String?;
            if (orderId == null || newStatus == null) return;
            if (_previousStatuses[orderId] == newStatus) return;
            _previousStatuses[orderId] = newStatus;
            _notificationService.showOrderStatusNotification(
              orderId: orderId,
              newStatus: newStatus,
            );
            if (mounted) {
              context.read<OrderHistoryCubit>().refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Order #$orderId is now ${newStatus.toUpperCase()}',
                  ),
                  backgroundColor: _statusColor(newStatus),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
        builder: (context, state) {
          if (state is OrderHistoryLoaded) {
            for (final o in state.orders) {
              if (o.id != null && o.status != null)
                _previousStatuses.putIfAbsent(o.id!, () => o.status!);
            }
          }
          if (state is OrderHistoryLoading)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            );
          if (state is OrderHistoryError)
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<OrderHistoryCubit>().loadOrders(),
            );
          if (state is OrderHistoryLoaded) return _LoadedView(state: state);
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final OrderHistoryLoaded state;
  const _LoadedView({required this.state});

  static const _statuses = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final orders = state.filtered;
    return RefreshIndicator(
      color: const Color(0xFF3B82F6),
      onRefresh: () => context.read<OrderHistoryCubit>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: state.selectedStatus == null,
                    onTap: () =>
                        context.read<OrderHistoryCubit>().filterByStatus(null),
                    color: const Color(0xFF3B82F6),
                  ),
                  ..._statuses.map(
                    (s) => _FilterChip(
                      label: _capitalize(s),
                      isSelected: state.selectedStatus == s,
                      onTap: () =>
                          context.read<OrderHistoryCubit>().filterByStatus(s),
                      color: _statusColor(s),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.orders.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${orders.length} order${orders.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
            ),
          if (orders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyOrders(isFiltered: state.selectedStatus != null),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _OrderCard(order: orders[i]),
                  childCount: orders.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AppOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showOrderDetail(context, order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (order.createdAt != null)
                          Text(
                            _formatDate(order.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    _StatusBadge(status: order.status ?? 'pending'),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                if (order.items.isNotEmpty) ...[
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        ...order.items
                            .take(4)
                            .map((item) => _ProductThumb(item: item)),
                        if (order.items.length > 4)
                          _MoreThumb(count: order.items.length - 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  order.items.map((i) => i.productName ?? 'Item').join(', '),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 15,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${order.total?.toStringAsFixed(0) ?? '—'} EGP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
                if (order.status != null && order.status != 'cancelled') ...[
                  const SizedBox(height: 16),
                  AnimatedOrderTimeline(status: order.status!),
                ],
                if (order.status == 'cancelled') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This order was cancelled',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Horizontal Animated Timeline (in card) ─────────────────────────────────
class AnimatedOrderTimeline extends StatefulWidget {
  final String status;
  const AnimatedOrderTimeline({super.key, required this.status});
  @override
  State<AnimatedOrderTimeline> createState() => _AnimatedOrderTimelineState();
}

class _AnimatedOrderTimelineState extends State<AnimatedOrderTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  static const _steps = [
    (label: 'Pending', icon: Icons.hourglass_empty, sub: 'Placed'),
    (label: 'Confirmed', icon: Icons.check_circle_outline, sub: 'Preparing'),
    (label: 'Shipped', icon: Icons.local_shipping_outlined, sub: 'On the way'),
    (label: 'Delivered', icon: Icons.home_outlined, sub: 'Done!'),
  ];

  int get _currentIndex {
    switch (widget.status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'shipped':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Column(
          children: [
            Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIndex = i ~/ 2;
                  final isCompleted = stepIndex < _currentIndex;
                  return Expanded(
                    child: Stack(
                      children: [
                        Container(height: 3, color: Colors.grey[200]),
                        if (isCompleted)
                          FractionallySizedBox(
                            widthFactor: _anim.value,
                            child: Container(
                              height: 3,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                final stepIndex = i ~/ 2;
                final isCompleted = stepIndex <= _currentIndex;
                final isCurrent = stepIndex == _currentIndex;
                final step = _steps[stepIndex];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: isCurrent ? 36 : 28,
                  height: isCurrent ? 36 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? const Color(0xFF3B82F6)
                        : Colors.grey[200],
                    border: isCurrent
                        ? Border.all(color: const Color(0xFF3B82F6), width: 2.5)
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted && !isCurrent ? Icons.check : step.icon,
                      color: isCompleted ? Colors.white : Colors.grey[400],
                      size: isCurrent ? 18 : 14,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) return const Expanded(child: SizedBox());
                final stepIndex = i ~/ 2;
                final isCompleted = stepIndex <= _currentIndex;
                final isCurrent = stepIndex == _currentIndex;
                return SizedBox(
                  width: isCurrent ? 36 : 28,
                  child: Text(
                    _steps[stepIndex].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCompleted
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ── Vertical Timeline (in detail sheet) ────────────────────────────────────
class _VerticalTimeline extends StatelessWidget {
  final String status;
  const _VerticalTimeline({required this.status});

  static const _steps = [
    (
      title: 'Order Placed',
      sub: 'Your order has been received',
      icon: Icons.receipt_outlined,
    ),
    (
      title: 'Confirmed',
      sub: 'Your order is being prepared',
      icon: Icons.check_circle_outline,
    ),
    (
      title: 'Shipped',
      sub: 'Your order is on the way',
      icon: Icons.local_shipping_outlined,
    ),
    (
      title: 'Delivered',
      sub: 'Your order has been delivered!',
      icon: Icons.home_outlined,
    ),
  ];

  int get _currentIndex {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'shipped':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index <= _currentIndex;
        final isCurrent = index == _currentIndex;
        final isLast = index == _steps.length - 1;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 150)),
          curve: Curves.easeOut,
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[200],
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted ? Icons.check : step.icon,
                        color: isCompleted ? Colors.white : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 2,
                      height: 50,
                      color: isCompleted && index < _currentIndex
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCompleted
                                  ? Colors.black87
                                  : Colors.grey[400],
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.sub,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted
                              ? Colors.grey[600]
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Order Detail Sheet ──────────────────────────────────────────────────────
void _showOrderDetail(BuildContext context, AppOrder order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderDetailSheet(order: order),
  );
}

class _OrderDetailSheet extends StatelessWidget {
  final AppOrder order;
  const _OrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.createdAt != null)
                      Text(
                        _formatDate(order.createdAt!),
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                  ],
                ),
                _StatusBadge(status: order.status ?? 'pending'),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.status != null && order.status != 'cancelled') ...[
                    const Text(
                      'Order Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _VerticalTimeline(status: order.status!),
                    const SizedBox(height: 24),
                  ],
                  if (order.status == 'cancelled')
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Cancelled',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                'Contact support for assistance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => _DetailItemRow(item: item)),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Subtotal',
                    value:
                        '${((order.total ?? 0) - 50).toStringAsFixed(0)} EGP',
                  ),
                  const SizedBox(height: 8),
                  const _SummaryRow(label: 'Delivery', value: '50 EGP'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(),
                  ),
                  _SummaryRow(
                    label: 'Total',
                    value: '${order.total?.toStringAsFixed(0) ?? '—'} EGP',
                    isBold: true,
                    valueColor: const Color(0xFF3B82F6),
                  ),
                  if (order.shippingAddress != null &&
                      order.shippingAddress!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.shippingAddress!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small Widgets ───────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _capitalize(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final AppOrderItem item;
  const _ProductThumb({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: item.productImage?.isNotEmpty == true
            ? Image.network(
                item.productImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.fitness_center, color: Colors.grey),
              )
            : const Icon(Icons.fitness_center, color: Colors.grey),
      ),
    );
  }
}

class _MoreThumb extends StatelessWidget {
  final int count;
  const _MoreThumb({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF3B82F6).withOpacity(0.08),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _DetailItemRow extends StatelessWidget {
  final AppOrderItem item;
  const _DetailItemRow({required this.item});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.productImage?.isNotEmpty == true
                  ? Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fitness_center, color: Colors.grey),
                    )
                  : const Icon(Icons.fitness_center, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} EGP × ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(0)} EGP',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isBold ? Colors.black : Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final bool isFiltered;
  const _EmptyOrders({required this.isFiltered});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 60,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFiltered ? 'No orders found' : 'No orders yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isFiltered
                  ? 'Try a different filter.'
                  : 'When you place orders, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'confirmed':
      return const Color(0xFF3B82F6);
    case 'shipped':
      return Colors.purple;
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
