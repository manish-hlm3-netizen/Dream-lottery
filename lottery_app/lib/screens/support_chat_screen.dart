import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages(showSpinner: true);
    // Poll for new messages every 8 seconds when chat is open
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadMessages(showSpinner: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({required bool showSpinner}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final res = await _api.getChatMessages();
      if (res['success'] == true) {
        final List<dynamic> fetched = res['data']['messages'] ?? [];
        if (!mounted) return;
        
        // Only update state and scroll if there are new messages
        if (fetched.length != _messages.length || showSpinner) {
          setState(() {
            _messages = fetched;
            _isLoading = false;
          });
          _scrollToBottom();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _error = res['message'] ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (showSpinner) {
        setState(() {
          _error = 'Network error. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    try {
      final res = await _api.sendChatMessage(text);
      if (res['success'] == true) {
        final newMsg = res['data']['message'];
        if (!mounted) return;
        setState(() {
          _messages.add(newMsg);
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        if (!mounted) return;
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to send message')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please retry.')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('chat_support')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMessages(showSpinner: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: AppTheme.successColor.withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  lang.translate('connecting_support'),
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Message history list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadMessages(showSpinner: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('💬', style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'How can we help you today?',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Type your query below and our support team will reply instantly.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isUser = msg['sender'] == 'user';
                              
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Customer Care Tag
                                      if (!isUser)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4, bottom: 4),
                                          child: Text(
                                            'Customer Support 👨‍💼',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                        decoration: BoxDecoration(
                                          gradient: isUser ? AppTheme.primaryGradient : null,
                                          color: isUser ? null : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(isUser ? 16 : 2),
                                            bottomRight: Radius.circular(isUser ? 2 : 16),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                                        ),
                                        child: Text(
                                          msg['text'] ?? '',
                                          style: TextStyle(
                                            color: isUser ? Colors.white : AppTheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                                        child: Text(
                                          _formatTime(msg['createdAt']),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppTheme.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // Message input composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: lang.translate('type_message'),
                        border: InputBorder.none,
                        hintStyle: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isSending,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
