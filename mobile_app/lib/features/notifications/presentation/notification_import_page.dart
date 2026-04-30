import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/notification_listener_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../data/notification_models.dart';
import 'notification_import_bloc.dart';
import 'notification_import_event.dart';
import 'notification_import_state.dart';

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
  final NotificationListenerBridge _bridge = NotificationListenerBridge();
  final List<Map<String, String>> _recentNotifications = [];

  // MethodChannel 调用系统设置
  static const _platform = MethodChannel('com.financetracker/settings');

  @override
  void initState() {
    super.initState();
    context.read<NotificationImportBloc>().add(NotificationLoadDemo());
  }

  void _startListening() {
    _bridge.startListening(
      onNotification: (source, rawText) {
        if (!mounted) return;
        setState(() {
          _recentNotifications.insert(0, {'source': source, 'text': rawText});
          if (_recentNotifications.length > 20) {
            _recentNotifications.removeLast();
          }
        });
        // 自动解析并添加到待导入列表
        context.read<NotificationImportBloc>().add(
              NotificationIncoming(source: source, rawText: rawText),
            );
      },
    );
    setState(() => _isListening = true);
  }

  void _stopListening() {
    _bridge.dispose();
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
    _bridge.dispose();
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

  void _confirmImport() {
    if (_defaultCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入默认分类 ID'), backgroundColor: Colors.orange),
      );
      return;
    }
    context.read<NotificationImportBloc>().add(
          NotificationImportConfirmed(defaultCategoryId: _defaultCategoryId),
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
              // 通知监听状态
              _buildListenerStatus(),
              const Divider(),
              Expanded(
                child: _buildNotificationList(state),
              ),
            ],
          );
        },
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
            '自动捕获支付宝、微信支付通知，解析后添加到下方列表',
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

  Widget _buildNotificationList(NotificationImportState state) {
    if (state is NotificationImportLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<ParsedNotification> notifications = [];
    if (state is NotificationImportLoaded) {
      notifications = state.notifications;
    }

    return CustomScrollView(
      slivers: [
        // 手动输入区域
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
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
                            border: OutlineInputBorder(borderRadius: AppRadius.smRadius, borderSide: const BorderSide(color: AppColors.gray300)),
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
                            hintText: '默认分类 ID (UUID)',
                            border: OutlineInputBorder(borderRadius: AppRadius.smRadius, borderSide: const BorderSide(color: AppColors.gray300)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          onChanged: (v) => _defaultCategoryId = v.trim(),
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
          ),
        ),
        // 通知列表
        if (notifications.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('暂无待导入通知', style: TextStyle(color: AppColors.gray400))),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '待导入 ${notifications.length} 条',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
                  ),
                  FilledButton(
                    onPressed: _confirmImport,
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
                (context, index) {
                  final n = notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_sourceIcon(n.source), size: 20, color: _sourceColor(n.source)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '¥${(n.amount / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
                                ),
                              ),
                              if (n.counterparty.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray100,
                                    borderRadius: AppRadius.fullRadius,
                                  ),
                                  child: Text(n.counterparty, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                                ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.expenseRed500, size: 18),
                                onPressed: () => context.read<NotificationImportBloc>().add(NotificationRemove(index)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                DateFormat('MM-dd HH:mm').format(n.timestamp),
                                style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                n.source == 'alipay' ? '支付宝' : n.source == 'wechat' ? '微信' : '银行',
                                style: TextStyle(fontSize: 11, color: _sourceColor(n.source)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.rawText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: notifications.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
