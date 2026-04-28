import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    // 加载演示数据
    context.read<NotificationImportBloc>().add(NotificationLoadDemo());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入通知')),
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
              // 手动添加区域
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              labelText: '原始通知文本',
                              hintText: '粘贴支付宝/微信通知内容',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedSource,
                          items: const [
                            DropdownMenuItem(value: 'alipay', child: Text('支付宝')),
                            DropdownMenuItem(value: 'wechat', child: Text('微信')),
                          ],
                          onChanged: (v) => setState(() => _selectedSource = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '默认分类 ID（UUID）',
                              hintText: 'e.g. a1b2c3d4-...',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _defaultCategoryId = v.trim(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _addNotification,
                          icon: const Icon(Icons.add),
                          label: const Text('添加'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<NotificationImportBloc>().add(NotificationLoadDemo()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('加载演示数据'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 通知列表
              Expanded(
                child: _buildNotificationList(state),
              ),
            ],
          );
        },
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

    if (notifications.isEmpty) {
      return const Center(child: Text('暂无待导入通知'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '待导入 ${notifications.length} 条',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton(
                onPressed: _confirmImport,
                child: const Text('确认导入'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    n.source == 'alipay' ? Icons.alternate_email : Icons.chat,
                    color: n.source == 'alipay' ? Colors.blue : Colors.green,
                  ),
                  title: Text(
                    '${n.source.toUpperCase()}  ¥${(n.amount / 100).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.counterparty.isNotEmpty) Text('对方: ${n.counterparty}'),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(n.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        n.rawText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => context
                        .read<NotificationImportBloc>()
                        .add(NotificationRemove(index)),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
