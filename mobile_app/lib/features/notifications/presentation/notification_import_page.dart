import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../categories/data/categories_models.dart';
import '../../../core/notification_listener_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../data/notification_models.dart';
import 'notification_import_bloc.dart';
import 'notification_import_event.dart';
import 'notification_import_state.dart';

/// 商户分组数据
class _MerchantGroup {
  final String counterparty;
  final List<int> indices;
  int get totalAmount => indices.fold(0, (sum, i) => sum + _allNotifications[i].amount);
  ParsedNotification get first => _allNotifications[indices.first];
  String? get categoryId => first.categoryId;

  static List<ParsedNotification> _allNotifications = [];

  _MerchantGroup({required this.counterparty, required this.indices});

  static List<_MerchantGroup> group(List<ParsedNotification> notifications) {
    _allNotifications = notifications;
    final map = <String, List<int>>{};
    for (var i = 0; i < notifications.length; i++) {
      final cp = notifications[i].counterparty;
      if (cp.isEmpty) {
        map['其他'] = [...(map['其他'] ?? []), i];
      } else {
        map[cp] = [...(map[cp] ?? []), i];
      }
    }
    return map.entries.map((e) => _MerchantGroup(counterparty: e.key, indices: e.value)).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }
}

class NotificationImportPage extends StatefulWidget {
  const NotificationImportPage({super.key});

  @override
  State<NotificationImportPage> createState() => _NotificationImportPageState();
}

class _NotificationImportPageState extends State<NotificationImportPage> {
  final _textController = TextEditingController();
  String _selectedSource = 'alipay';
  String _defaultCategoryId = '';
  bool _isListening = false;
  final NotificationListenerBridge _bridge = NotificationListenerBridge.instance;
  final List<Map<String, String>> _recentNotifications = [];
  final Set<String> _savedRules = {}; // 跟踪已保存的规则关键词

  // MethodChannel 调用系统设置
  static const _platform = MethodChannel('com.financetracker/settings');

  @override
  void initState() {
    super.initState();
    // 恢复监听状态
    _isListening = _bridge.isListening;
    context.read<NotificationImportBloc>().add(NotificationLoadDemo());
  }

  Future<void> _startListening() async {
    await _bridge.startListening(
      onNotification: (source, rawText) {
        if (!mounted) return;
        setState(() {
          _recentNotifications.insert(0, {'source': source, 'text': rawText});
          if (_recentNotifications.length > 20) {
            _recentNotifications.removeLast();
          }
        });
        context.read<NotificationImportBloc>().add(
              NotificationIncoming(source: source, rawText: rawText),
            );
      },
    );
    if (mounted) setState(() => _isListening = true);
  }

  void _stopListening() {
    _bridge.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _openNotificationSettings() async {
    try {
      await _platform.invokeMethod('openNotificationListenerSettings');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请手动进入系统设置 → 通知使用权')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addNotification() {
    if (_textController.text.trim().isEmpty) return;
    context.read<NotificationImportBloc>().add(
          NotificationAdd(rawText: _textController.text.trim(), source: _selectedSource),
        );
    _textController.clear();
  }

  void _confirmImport(String defaultCategoryId) {
    // 检查是否有未指定分类的通知
    final bloc = context.read<NotificationImportBloc>();
    // 通过检查当前 BLoC 是否还有未设分类的通知（简化处理）
    // 实际：如果 defaultCategoryId 为空且有通知未分类，提示用户
    // 如果全部已分类，即使 defaultCategoryId 为空也能导入
    final state = bloc.state;
    if (state is NotificationImportLoaded) {
      final hasUncategorized = state.notifications.any((n) => n.categoryId == null);
      if (hasUncategorized && defaultCategoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择默认分类或为每组指定分类'), backgroundColor: Colors.orange),
        );
        return;
      }
    } else if (defaultCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择默认分类'), backgroundColor: Colors.orange),
      );
      return;
    }
    context.read<NotificationImportBloc>().add(
          NotificationImportConfirmed(defaultCategoryId: defaultCategoryId),
        );
  }

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'alipay':
        return Icons.alternate_email;
      case 'wechat':
        return Icons.chat;
      default:
        return Icons.sms;
    }
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'alipay':
        return const Color(0xFF1677FF);
      case 'wechat':
        return const Color(0xFF07C160);
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知导入')),
      body: BlocConsumer<NotificationImportBloc, NotificationImportState>(
        listener: (context, state) {
          if (state is NotificationImportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导入完成：新建 ${state.result.created} 条，跳过 ${state.result.skipped} 条'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is NotificationImportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildListenerStatus(),
              const Divider(),
              Expanded(
                child: _buildContent(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(NotificationImportState state) {
    if (state is NotificationImportLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is! NotificationImportLoaded) {
      return const SizedBox.shrink();
    }

    final notifications = state.notifications;
    final categories = state.categories;
    final groups = _MerchantGroup.group(notifications);

    if (notifications.isEmpty) {
      return _buildInputSection(categories);
    }

    return CustomScrollView(
      slivers: [
        // 手动输入区域
        SliverToBoxAdapter(
          child: _buildInputSection(categories),
        ),
        // 商户分组列表
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '待导入 ${notifications.length} 条（${groups.length} 组）',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
                ),
                FilledButton(
                  onPressed: () => _confirmImport(_defaultCategoryId),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.gray900),
                  child: const Text('确认导入'),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, groupIndex) {
                final group = groups[groupIndex];
                final hasCategorySet = group.categoryId != null;
                final categoryName = hasCategorySet
                    ? categories.where((c) => c.id == group.categoryId!).firstOrNull?.name ?? '已选'
                    : '未选';
                final ruleSaved = _savedRules.contains(group.counterparty);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 商户名 + 总金额
                        Row(
                          children: [
                            Icon(
                              _sourceIcon(group.first.source),
                              size: 18,
                              color: _sourceColor(group.first.source),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                group.counterparty,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900),
                              ),
                            ),
                            Text(
                              '¥${(group.totalAmount / 100).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900),
                            ),
                            if (group.indices.length > 1)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: AppRadius.fullRadius,
                                ),
                                child: Text('×${group.indices.length}', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // 分类选择
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: hasCategorySet ? group.categoryId : null,
                                decoration: InputDecoration(
                                  labelText: '分类',
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.smRadius,
                                    borderSide: const BorderSide(color: AppColors.gray300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                hint: const Text('选择分类', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                                items: categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    context.read<NotificationImportBloc>().add(
                                          NotificationSetGroupCategory(
                                            counterparty: group.counterparty,
                                            categoryId: v,
                                          ),
                                        );
                                  }
                                },
                                isDense: true,
                                style: const TextStyle(fontSize: 13, color: AppColors.gray900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 记住分类按钮
                            if (hasCategorySet && !ruleSaved)
                              SizedBox(
                                height: 32,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context.read<NotificationImportBloc>().add(
                                          NotificationSaveRule(
                                            keyword: group.counterparty,
                                            categoryId: group.categoryId!,
                                          ),
                                        );
                                    setState(() => _savedRules.add(group.counterparty));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${group.counterparty} → $categoryName 已记住'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.save, size: 14),
                                  label: const Text('记住', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    foregroundColor: AppColors.incomeGreen600,
                                    side: BorderSide(color: AppColors.incomeGreen600.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                                  ),
                                ),
                              ),
                            if (ruleSaved)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.check_circle, size: 18, color: AppColors.incomeGreen600),
                              ),
                          ],
                        ),
                        if (group.indices.length > 1) ...[
                          const SizedBox(height: AppSpacing.sm),
                          // 原始通知列表（收起状态）
                          ...group.indices.take(2).map((i) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  notifications[i].rawText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                                ),
                              )),
                          if (group.indices.length > 2)
                            Text(
                              '还有 ${group.indices.length - 2} 条...',
                              style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: groups.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListenerStatus() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isListening ? Icons.headset_mic : Icons.headset_off,
                color: _isListening ? AppColors.incomeGreen600 : AppColors.gray400,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '通知监听',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isListening ? AppColors.incomeGreen600.withOpacity(0.1) : AppColors.gray100,
                  borderRadius: AppRadius.fullRadius,
                ),
                child: Text(
                  _isListening ? '运行中' : '未启动',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isListening ? AppColors.incomeGreen600 : AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '自动捕获支付宝、微信支付通知，解析后按商户分组归类',
            style: TextStyle(fontSize: 12, color: AppColors.gray400, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: _isListening
                      ? TextButton.icon(
                          onPressed: _stopListening,
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('停止监听', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.expenseRed500),
                        )
                      : TextButton.icon(
                          onPressed: _startListening,
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('开始监听', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.incomeGreen600),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: TextButton.icon(
                  onPressed: _openNotificationSettings,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('授权设置', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.gray600),
                ),
              ),
            ],
          ),
          if (_recentNotifications.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            const Text('最近捕获', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500)),
            const SizedBox(height: 4),
            ..._recentNotifications.take(3).map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(_sourceIcon(n['source']!), size: 14, color: _sourceColor(n['source']!)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          n['text']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection(List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('手动添加', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '粘贴支付宝/微信通知内容',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.smRadius,
                        borderSide: const BorderSide(color: AppColors.gray300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    DropdownButton<String>(
                      value: _selectedSource,
                      items: const [
                        DropdownMenuItem(value: 'alipay', child: Text('支付宝', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'wechat', child: Text('微信', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'bank', child: Text('银行', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _selectedSource = v!),
                      underline: const SizedBox(),
                      isDense: true,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 64,
                      height: 32,
                      child: TextButton(
                        onPressed: _addNotification,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.gray900,
                          foregroundColor: AppColors.surface,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                        ),
                        child: const Text('添加', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '默认分类（未设分类的归属）',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.smRadius,
                        borderSide: const BorderSide(color: AppColors.gray300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _defaultCategoryId = v.trim()),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => context.read<NotificationImportBloc>().add(NotificationLoadDemo()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                    ),
                    child: const Text('演示', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
