import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  _MerchantGroup({required this.counterparty, required this.indices});

  int totalAmount(List<ParsedNotification> all) =>
      indices.fold(0, (sum, i) => sum + all[i].amount);

  ParsedNotification first(List<ParsedNotification> all) => all[indices.first];

  String? categoryId(List<ParsedNotification> all) => first(all).categoryId;

  /// 按商户名分组（P0: 移除 static 字段，全部通过参数传入）
  static List<_MerchantGroup> group(List<ParsedNotification> notifications) {
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
      ..sort((a, b) {
        final aTotal = a.totalAmount(notifications);
        final bTotal = b.totalAmount(notifications);
        return bTotal.compareTo(aTotal);
      });
  }
}

class NotificationImportPage extends StatefulWidget {
  const NotificationImportPage({super.key});

  @override
  State<NotificationImportPage> createState() => _NotificationImportPageState();
}

class _NotificationImportPageState extends State<NotificationImportPage> {
  String _defaultCategoryId = '';
  bool _isListening = false;
  final NotificationListenerBridge _bridge = NotificationListenerBridge.instance;
  final List<Map<String, String>> _recentNotifications = [];
  final Set<String> _savedRules = {};

  // MethodChannel 调用系统设置
  static const _platform = MethodChannel('com.financetracker/settings');

  @override
  void initState() {
    super.initState();
    _isListening = _bridge.isListening;
    if (_isListening) {
      // 桥仍在运行，但回调指向旧页面 → 必须更新
      _bridge.updateCallback(onNotification: _onNotificationReceived);
    }
    context.read<NotificationImportBloc>().add(const NotificationInit());
  }

  /// 通知到达时的统一处理
  void _onNotificationReceived(String source, String rawText) {
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
  }

  Future<void> _startListening() async {
    await _bridge.startListening(
      onNotification: _onNotificationReceived,
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

  void _confirmImport(String defaultCategoryId) {
    final bloc = context.read<NotificationImportBloc>();
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

  String _sourceLabel(String source) {
    switch (source) {
      case 'alipay':
        return '支付宝';
      case 'wechat':
        return '微信';
      case 'bank':
        return '银行';
      default:
        return '其他';
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

  String _formatTimestamp(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
    final parsed = notifications.where((n) => !n.isUnparsed).toList();
    final unparsed = notifications.where((n) => n.isUnparsed).toList();
    final groups = _MerchantGroup.group(parsed);

    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray300),
            SizedBox(height: 12),
            Text(
              '暂无通知',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray400),
            ),
            SizedBox(height: 4),
            Text(
              '开启通知监听后，支付宝/微信/招商银行的支付通知会自动抓取',
              style: TextStyle(fontSize: 12, color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // === 无法解析的通知 ===
        if (unparsed.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildUnparsedSection(unparsed),
          ),
        // 待导入计数 + 默认分类 + 确认按钮
        if (parsed.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '待导入 ${parsed.length} 条（${groups.length} 组）',
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
          // 默认分类选择
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: DropdownButtonFormField<String>(
                value: _defaultCategoryId.isEmpty ? null : _defaultCategoryId,
                decoration: InputDecoration(
                  labelText: '默认分类（未设分类的通知归属）',
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
                    setState(() => _defaultCategoryId = v);
                  }
                },
                isDense: true,
                style: const TextStyle(fontSize: 13, color: AppColors.gray900),
              ),
            ),
          ),
        ],
        // 商户分组列表
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, groupIndex) {
                final group = groups[groupIndex];
                final hasCategorySet = group.categoryId(parsed) != null;
                final categoryName = hasCategorySet
                    ? categories.where((c) => c.id == group.categoryId(parsed)!).firstOrNull?.name ?? '已选'
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
                              _sourceIcon(group.first(parsed).source),
                              size: 18,
                              color: _sourceColor(group.first(parsed).source),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                group.counterparty,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900),
                              ),
                            ),
                            // ignore: prefer_const_constructors
                            Text(
'¥\${(group.totalAmount(parsed) / 100).toStringAsFixed(2)}',
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
                                value: hasCategorySet ? group.categoryId(parsed) : null,
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
                                            categoryId: group.categoryId(parsed)!,
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
                          ...group.indices.take(2).map((i) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  parsed[i].rawText,
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

  /// 无法解析的通知区域
  Widget _buildUnparsedSection(List<ParsedNotification> unparsed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                '${unparsed.length} 条通知未能解析',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
              ),
              const Spacer(),
              const Text(
                '请联系开发者添加解析规则',
                style: TextStyle(fontSize: 11, color: AppColors.gray400),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...unparsed.asMap().entries.map((entry) {
            final idx = entry.key;
            final n = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 来源 + 时间
                    Row(
                      children: [
                        Icon(_sourceIcon(n.source), size: 16, color: _sourceColor(n.source)),
                        const SizedBox(width: 6),
                        Text(
                          _sourceLabel(n.source),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _sourceColor(n.source)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(n.timestamp),
                          style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 原文（全文显示，不截断）
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: SelectableText(
                        n.rawText,
                        style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 操作按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 复制原文
                        SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: n.rawText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('原文已复制'), duration: Duration(seconds: 1)),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('复制原文', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              foregroundColor: AppColors.gray600,
                              side: const BorderSide(color: AppColors.gray300),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 删除（移除）
                        SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<NotificationImportBloc>().add(
                                    NotificationRemove(idx),
                                  );
                            },
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('忽略', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              foregroundColor: AppColors.expenseRed500,
                              side: BorderSide(color: AppColors.expenseRed500.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(),
        ],
      ),
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
}
